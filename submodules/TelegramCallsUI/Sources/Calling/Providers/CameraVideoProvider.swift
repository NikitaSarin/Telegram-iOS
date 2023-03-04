//
//  CameraVideoProvider.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 24.02.2023.
//

import AVFoundation
import CoreImage

final class CameraVideoProvider: NSObject {

    enum Error: Swift.Error {
        case noAccessToCamera
    }

    weak var delegate: OutgoingVideoProviderDelegate?

    var position: AVCaptureDevice.Position {
        didSet {
            guard position != oldValue else { return }
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                try? updateInput(for: position)

                videoConnection?.videoOrientation = .portrait
                videoConnection?.isVideoMirrored = position == .front
            }
        }
    }

    private var session: AVCaptureSession?
    private var input: AVCaptureDeviceInput?
    private let videoQueue = DispatchQueue(label: "com.telegram.calls.video")
    private var videoOutput: AVCaptureOutput?

    private var videoConnection: AVCaptureConnection? { videoOutput?.connection(with: .video) }

    init(position: AVCaptureDevice.Position) {
        self.position = position
    }

    func setup() throws {
        droppedFramesCount = 0
        guard session == nil else { return }

        let session = AVCaptureSession()
        session.sessionPreset = .high
        self.session = session

        try updateInput(for: position)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        self.videoOutput = videoOutput
        videoConnection?.videoOrientation = .portrait
        videoConnection?.isVideoMirrored = position == .front
    }

    func start() {
        session?.startRunning()
    }

    func stop() {
        session?.stopRunning()
    }

    var droppedFramesCount = 0

    private lazy var context: CIContext = {
        if let device = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: device)
        } else {
            return  CIContext()
        }
    }()
}

extension CameraVideoProvider: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard
            connection.videoOrientation == .portrait,
            connection.isVideoOrientationSupported
        else { return }

        guard droppedFramesCount > 3 else {
            if droppedFramesCount == 1 {
                delegate?.outgoingProviderDidStartReceivingCorrectBuffers()
            }
            droppedFramesCount += 1
            return
        }

        delegate?.outgoingProviderDidEnqueue(sampleBuffer: sampleBuffer)
//        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//        let image = CIImage(cvPixelBuffer: imageBuffer)
//        let outputimage = image.applyingGaussianBlur(sigma: 20)
//
//        if let blurredSampleBuffer = render(image: outputimage, from: sampleBuffer), false {
//            layer?.enqueue(blurredSampleBuffer)
//        } else {
//            layer?.enqueue(sampleBuffer)
//        }
    }

    func render(image: CIImage, from sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
        let inputPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        var pixelBufferRef: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorSystemDefault,
                            CVPixelBufferGetWidth(inputPixelBuffer),
                            CVPixelBufferGetHeight(inputPixelBuffer),
                            CVPixelBufferGetPixelFormatType(inputPixelBuffer),
                            nil,
                            &pixelBufferRef)

        guard let outputPixelBuffer = pixelBufferRef else { return nil }
        context.render(image, to: outputPixelBuffer)

        var videoInfo: CMVideoFormatDescription? = nil
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: outputPixelBuffer,
            formatDescriptionOut: &videoInfo
        )

        guard let videoInfo = videoInfo else { return nil }

        var sampleTime = CMSampleTimingInfo()
//        sampleTime.duration = CMSampleBufferGetDuration(sampleBuffer)
//        sampleTime.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//        sampleTime.decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)

        var outputSampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: outputPixelBuffer,
            formatDescription: videoInfo,
            sampleTiming: &sampleTime,
            sampleBufferOut: &outputSampleBuffer
        )
//        CMSampleBufferCreateForImageBuffer(
//            allocator: kCFAllocatorDefault,
//            imageBuffer: outputPixelBuffer,
//            dataReady: true,
//            makeDataReadyCallback: nil,
//            refcon: nil,
//            formatDescription: videoInfo,
//            sampleTiming: &sampleTime,
//            sampleBufferOut: &outputSampleBuffer
//        )

        return outputSampleBuffer
    }
}

private extension CameraVideoProvider {

    func updateInput(for position: AVCaptureDevice.Position) throws {
        guard
            let session = session,
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: position)
        else { throw Error.noAccessToCamera }
        droppedFramesCount = 0
        if let oldInput = input {
            session.removeInput(oldInput)
        }
        let newInput = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(newInput) {
            session.addInput(newInput)
        }
        input = newInput
    }
}
