//
//  RotationViewController.swift
//  TelegramCalls
//

import UIKit
import Metal
import MetalKit
import GLKit
import MetalPerformanceShaders
import CallsEmoji

struct SceneMatrices {
  var projectionMatrix: GLKMatrix4 = GLKMatrix4Identity
  var modelviewMatrix: GLKMatrix4 = GLKMatrix4Identity
}

private enum Colors {

    static let initiatingCall = GradientColors(
        leftUp: UIColor(hex: "5295D6"),
        leftDown: UIColor(hex: "AC65D4"),
        rightUp: UIColor(hex: "616AD5"),
        rightDown: UIColor(hex: "AC65D4")
    )

    static let callEstablished = GradientColors(
        leftUp: UIColor(hex: "BAC05D"),
        leftDown: UIColor(hex: "398D6F"),
        rightUp: UIColor(hex: "3C9C8F"),
        rightDown: UIColor(hex: "53A6DE")
    )

    static let weakSignal = GradientColors(
        leftUp: UIColor(hex: "B84498"),
        leftDown: UIColor(hex: "FF7E46"),
        rightUp: UIColor(hex: "F4992E"),
        rightDown: UIColor(hex: "C94986")
    )
}

final class GradientViewController: UIViewController {

    enum State: CaseIterable {
        case initiatingCall
        case callEstablished
        case weakSignal

        var colors: GradientColors {
            switch self {
            case .initiatingCall:
                return Colors.initiatingCall
            case .callEstablished:
                return Colors.callEstablished
            case .weakSignal:
                return Colors.weakSignal
            }
        }
    }

    private let viewModel: GradientViewModel
    private var mtkView: MTKView? { view as? MTKView }
    private var state: State

    init(state: State) {
        self.state = state
        viewModel = GradientViewModel(colors: state.colors)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        view = MTKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.configure()

        mtkView?.device = viewModel.device
        mtkView?.delegate = viewModel
        mtkView?.framebufferOnly = false
    }

    func set(state: State) {
        guard self.state != state else { return }
        self.state = state
        viewModel.transite(to: state.colors)
    }
}

struct GradientColors {
    let leftUp: UIColor
    let leftDown: UIColor
    let rightUp: UIColor
    let rightDown: UIColor
}

final class GradientViewModel: NSObject {

    let device = MTLCreateSystemDefaultDevice()

    private var rotation: Float = 0.0
    private var sceneMatrices = SceneMatrices()
    private var lastUpdateDate = Date()
    private var uniformBuffer: MTLBuffer?

    private var commandQueue: MTLCommandQueue?
    private var renderPipelineState: MTLRenderPipelineState?

    private lazy var vertexBuffer = makeVertexBuffer()
    private var colors: GradientColors
    private var progress: CGFloat = 0
    private var timer: Timer?

    private var fromColors: GradientColors?
    private var toColors: GradientColors?

    init(colors: GradientColors) {
        self.colors = colors
    }

    func transite(to colors: GradientColors) {
        fromColors = self.colors
        toColors = colors
        timer = Timer.scheduledTimer(
            timeInterval: 1 / 30,
            target: self,
            selector: #selector(updateTransition),
            userInfo: nil,
            repeats: true
        )
        progress = 0
    }

    func configure() {
        let mainBundle = Bundle(for: GradientViewModel.self)
        guard
            let device = device,
            let commandQueue = device.makeCommandQueue(),
            let path = mainBundle.path(forResource: "TelegramCallsUIBundle", ofType: "bundle"),
            let bundle = Bundle(path: path),
            let library = try? device.makeDefaultLibrary(bundle: bundle)
        else {
            return
        }

        self.commandQueue = commandQueue

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "rotation_vertex")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "rotation_fragment")
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        guard
            let state = try? device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        else { return }

        self.renderPipelineState = state
    }
}
extension GradientViewModel: MTKViewDelegate {

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = fabsf(Float(size.width) / Float(size.height))  // 1
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), aspect, 4.0, 10.0)  // 2
        sceneMatrices.projectionMatrix = projectionMatrix  // 3
    }

    func draw(in view: MTKView) {
        guard
            let drawable = view.currentDrawable,
            let device = device,
            let commandQueue = commandQueue,
            let renderPipelineState = renderPipelineState
        else {
            return
        }

        let colorAttachmentDescriptor = MTLRenderPassColorAttachmentDescriptor()
        colorAttachmentDescriptor.texture = drawable.texture
        colorAttachmentDescriptor.loadAction = .clear
        colorAttachmentDescriptor.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0] = colorAttachmentDescriptor

        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }

        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // Update logic
        var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -6.0)
        let timeSinceLastUpdate = lastUpdateDate.timeIntervalSince(Date())
        rotation -= 60 * Float(timeSinceLastUpdate) // 1x
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(rotation), 0, 0, 1)  // 2
        modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 4.5, 4.5, 1)
        sceneMatrices.modelviewMatrix = modelViewMatrix

        // Set uniform buffer
        let uniformBufferSize = MemoryLayout.size(ofValue: sceneMatrices)
        uniformBuffer = device.makeBuffer(bytes: &sceneMatrices,
                                           length: uniformBufferSize,
                                           options: .storageModeShared) // 2
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)  // 3

        renderEncoder.setRenderPipelineState(renderPipelineState)

        renderEncoder.drawPrimitives(
            type: .triangleStrip,
            vertexStart: 0,
            vertexCount: 4)
        renderEncoder.endEncoding()

        var texture = drawable.texture
        let kernel = MPSImageGaussianBlur(device: device, sigma: 10)
        kernel.encode(commandBuffer: commandBuffer, inPlaceTexture: &texture, fallbackCopyAllocator: nil)

        commandBuffer.addCompletedHandler { _ in
          self.lastUpdateDate = Date()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

private extension GradientViewModel {

    func makeVertexBuffer() -> MTLBuffer? {
        guard
            let device = device
        else { return nil }

        var array = [
            VertexRotation(position: [-1, 1, 0], color: colors.leftUp.mtl), // LU
            VertexRotation(position: [-1, -1, 0], color: colors.leftDown.mtl), // LD
            VertexRotation(position: [1, 1, 0], color: colors.rightUp.mtl), // RU
            VertexRotation(position: [1, -1, 0], color: colors.rightDown.mtl) // RD
        ]
        return device.makeBuffer(
            bytes: &array,
            length: MemoryLayout<VertexRotation>.stride * array.count,
            options: .storageModeShared
        )
    }

    @objc func updateTransition() {
        guard
            let fromColors = fromColors,
            let toColors = toColors
        else { return  }
        progress += 0.05
        guard progress <= 1  else {
            colors = toColors
            finishTransition()
            return
        }
        colors = GradientColors(
            leftUp: fromColors.leftUp.interpolated(to: toColors.leftUp, progress: progress),
            leftDown: fromColors.leftDown.interpolated(to: toColors.leftDown, progress: progress),
            rightUp: fromColors.rightUp.interpolated(to: toColors.rightUp, progress: progress),
            rightDown: fromColors.rightDown.interpolated(to: toColors.rightDown, progress: progress)
        )
        vertexBuffer = makeVertexBuffer()
    }

    func finishTransition() {
        toColors = nil
        fromColors = nil
        timer?.invalidate()
        timer = nil
        vertexBuffer = makeVertexBuffer()
    }
}
