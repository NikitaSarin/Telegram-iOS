//
//  OutgoingVideoProvider.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 24.02.2023.
//

import AVFoundation

protocol OutgoingVideoProviderDelegate: AnyObject {

    func outgoingProviderDidStartReceivingCorrectBuffers()

    func outgoingProviderDidEnqueue(sampleBuffer: CMSampleBuffer)
}

final class OutgoingVideoProvider {

    var source: VideoSourceType = .frontCamera {
        didSet {
            guard source != oldValue else { return }

            switch source {
            case .frontCamera:
                camera.position = .front
            case .backCamera:
                camera.position = .back
            case .phoneScreen:
                break
            }
        }
    }

    let camera = CameraVideoProvider(position: .front)

    func set(delegate: OutgoingVideoProviderDelegate) {
        camera.delegate = delegate
    }

    func setup() throws {
        switch source {
        case .frontCamera, .backCamera:
            try camera.setup()
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                camera.start()
            }
        case .phoneScreen:
            break
        }
    }

    func start() {
        switch source {
        case .frontCamera, .backCamera:
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                camera.start()
            }
        case .phoneScreen:
            break
        }
    }

    func stop() {
        camera.stop()
    }
}
