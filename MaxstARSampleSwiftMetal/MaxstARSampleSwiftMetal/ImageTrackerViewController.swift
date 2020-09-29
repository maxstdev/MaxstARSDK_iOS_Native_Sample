//
//  ImageTrackerViewController.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 12..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import MaxstARSDKFramework
import MaxstVideoFramework

class ImageTrackerViewController: UIViewController, MTKViewDelegate {
    
    @IBOutlet var normalSwitch: UISwitch!
    @IBOutlet var multiSwitch: UISwitch!
    @IBOutlet var extendSwitch: UISwitch!

    var cameraDevice:MasCameraDevice = MasCameraDevice()
    var trackingManager:MasTrackerManager = MasTrackerManager()
    var cameraResultCode:MasResultCode = MasResultCode.CameraPermissionIsNotResolved
    
    var videoCaptureController:VideoCaptureController = VideoCaptureController()
    var chromakeyVideoCaptureController:VideoCaptureController = VideoCaptureController()
    
    var textureCube:TextureCube?
    var videoPanelRenderer:VideoPanelRenderer! = nil
    var chromakeyVideoPanelRenderer:ChromakeyVideoPanelRenderer! = nil
    var colorCube:ColorCube?
    var backgroundCameraQuad:BackgroundCameraQuad?
    
    @IBOutlet var metalView: MTKView!
    var commandQueue:MTLCommandQueue?
    var device:MTLDevice!
    
    var screenSizeWidth:Float = 0.0
    var screenSizeHeight:Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        
        extendSwitch.setOn(false, animated: false)
        multiSwitch.setOn(false, animated: false)
        normalSwitch.setOn(true, animated: false)
        
        let maxstAR_cubePath = Bundle.main.path(forResource: "MaxstAR_Cube", ofType: "png", inDirectory: "data/Texture")!
        let maxst_CubeImage = UIImage(contentsOfFile: maxstAR_cubePath)!
        textureCube?.setTexture(textureImage: maxst_CubeImage)
        
        trackingManager.setTrackingOption(.NORMAL_TRACKING)

        startEngine()
        
        NotificationCenter.default.addObserver(self, selector: #selector(pauseAR), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackgournd), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeAR), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pauseAR()
        videoCaptureController.stop()
        chromakeyVideoCaptureController.stop()
        trackingManager.destroyTracker()
        MasMaxstAR.deinit()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupMetal() {
        self.metalView?.delegate = self
        self.metalView?.device = MTLCreateSystemDefaultDevice()!
        self.metalView?.preferredFramesPerSecond = 60;
        self.device = self.metalView?.device
        self.commandQueue = device!.makeCommandQueue()
        
        let moviePath1 = Bundle.main.path(forResource: "VideoSample", ofType: "mp4", inDirectory: "data/Video")!
        let moviePath2 = Bundle.main.path(forResource: "ShutterShock", ofType: "mp4", inDirectory: "data/Video")!
        
        videoPanelRenderer = VideoPanelRenderer.init(device: self.device)
        chromakeyVideoPanelRenderer = ChromakeyVideoPanelRenderer.init(device: self.device)
        videoCaptureController.open(moviePath1, repeat: true, isMetal: true, context:self.device)
        chromakeyVideoCaptureController.open(moviePath2, repeat: true, isMetal: true, context:self.device)
        
        videoPanelRenderer.setVideoSize(width: Int(videoCaptureController.getVideoWidth()), height: Int(videoCaptureController.getVideoHeight()))
        chromakeyVideoPanelRenderer.setVideoSize(width: Int(chromakeyVideoCaptureController.getVideoWidth()), height: Int(chromakeyVideoCaptureController.getVideoHeight()))
        
        textureCube = TextureCube(device: self.device)
        colorCube = ColorCube(device: self.device)
        
        backgroundCameraQuad = BackgroundCameraQuad(device: self.device)
        
        screenSizeWidth = Float(UIScreen.main.nativeBounds.size.width)
        screenSizeHeight = Float(UIScreen.main.nativeBounds.size.height)
        
        MasMaxstAR.onSurfaceChanged(Int32(screenSizeWidth), height: Int32(screenSizeHeight))
    }
    
    func openCamera() {
        let userDefaults:UserDefaults = UserDefaults.standard
        var resolution:Int = userDefaults.integer(forKey: "CameraResolution")
        
        if resolution == 0 {
            resolution = 640
            userDefaults.set(640, forKey: "CameraResolution")
        }
        
        if resolution == 1280 {
            cameraResultCode = cameraDevice.start(0, width: 1280, height: 720)
        } else if resolution == 640 {
            cameraResultCode = cameraDevice.start(0, width: 640, height: 480)
        } else if resolution == 1920 {
            cameraResultCode = cameraDevice.start(0, width: 1920, height: 1080)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        _depthTexture = nil
    }
    
    func draw(in view: MTKView) {
        if let drawable = view.currentDrawable {
            let commandBuffer:MTLCommandBuffer = self.commandQueue!.makeCommandBuffer()!
            let renderPass:MTLRenderPassDescriptor = self.renderPassForDrawable(drawable: drawable)
            
            let commandEncoder:MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
            let trackingState:MasTrackingState = trackingManager.updateTrackingState()
            let result:MasTrackingResult = trackingState.getTrackingResult()
            
            let backgroundImage:MasTrackedImage = trackingState.getImage()
            let backgroundProjectionMatrix:matrix_float4x4 = cameraDevice.getBackgroundPlaneProjectionMatrix()

            let projectionMatrix:matrix_float4x4 = cameraDevice.getProjectionMatrix()
        
            if let cameraQuad = backgroundCameraQuad {
                cameraQuad.setProjectionMatrix(projectionMatrix: backgroundProjectionMatrix)
                cameraQuad.draw(commandEncoder: commandEncoder, image: backgroundImage)
            }
            
            let trackingCount:Int32 = result.getCount()
            
            if trackingCount > 0 {
                for i in stride(from: 0, to: trackingCount, by: 1) {
                    let trackable:MasTrackable = result.getTrackable(i)
                    let poseMatrix:matrix_float4x4 = trackable.getPose()
                    
                    if trackable.getName() == "Lego" {
                        if videoCaptureController.getState() == MEDIA_STATE.PLAYING {
                            videoCaptureController.play()
                            videoCaptureController.update()
                            
                            videoPanelRenderer.setProjectionMatrix(projectionMatrix: projectionMatrix)
                            videoPanelRenderer.setPoseMatrix(poseMatrix: poseMatrix)
                            videoPanelRenderer.setTranslation(x: 0.0, y: 0.0, z: 0.0)
                            videoPanelRenderer.setScale(x: 0.26, y: 0.15, z: 1.0)
                            videoPanelRenderer.draw(commandEncoder: commandEncoder, videoTextureId: videoCaptureController.getMetalTextureId())
                        }
                    } else if trackable.getName() == "Blocks" {
                        if chromakeyVideoCaptureController.getState() == MEDIA_STATE.PLAYING {
                            chromakeyVideoCaptureController.play()
                            chromakeyVideoCaptureController.update()
                            
                            chromakeyVideoPanelRenderer.setProjectionMatrix(projectionMatrix: projectionMatrix)
                            chromakeyVideoPanelRenderer.setPoseMatrix(poseMatrix: poseMatrix)
                            chromakeyVideoPanelRenderer.setTranslation(x: 0.0, y: 0.0, z: 0.0)
                            chromakeyVideoPanelRenderer.setScale(x: 0.26, y: 0.18, z: 1.0)
                            chromakeyVideoPanelRenderer.draw(commandEncoder: commandEncoder, videoTextureId: chromakeyVideoCaptureController.getMetalTextureId())
                        }
                    } else if trackable.getName() == "Glacier" {
                        textureCube!.setProjectionMatrix(projectionMatrix: projectionMatrix)
                        textureCube!.setPoseMatrix(poseMatrix: poseMatrix)
                        textureCube!.setTranslation(x: 0.0, y: 0.0, z: -0.025)
                        textureCube!.setScale(x: 0.15, y:  0.15, z: 0.05)
                        textureCube!.draw(commandEncoder: commandEncoder)
                    } else {
                        colorCube!.setProjectionMatrix(projectionMatrix: projectionMatrix)
                        colorCube!.setPoseMatrix(poseMatrix: poseMatrix)
                        colorCube!.setTranslation(x: 0.0, y: 0.0, z: -0.075)
                        colorCube!.setScale(x: 0.15, y: 0.15, z: 0.15)
                        colorCube!.draw(commandEncoder: commandEncoder)
                    }
                }
            } else {
                videoCaptureController.pause()
                chromakeyVideoCaptureController.pause()
            }
            commandEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
    
    var _depthTexture:MTLTexture?
    
    func renderPassForDrawable(drawable: CAMetalDrawable) -> MTLRenderPassDescriptor {
        let renderPass:MTLRenderPassDescriptor = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = drawable.texture
        renderPass.colorAttachments[0].loadAction = MTLLoadAction.clear
        renderPass.colorAttachments[0].storeAction = MTLStoreAction.store
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 1.0, 0.0, 1.0)
        
        if _depthTexture == nil {
            let textureDescriptor:MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: drawable.texture.width, height: drawable.texture.height, mipmapped: false)
            textureDescriptor.storageMode = .private
            textureDescriptor.usage = .renderTarget
            
            _depthTexture = device?.makeTexture(descriptor: textureDescriptor)
        }
        
        renderPass.depthAttachment.texture = _depthTexture
        
        return renderPass
    }
    
    func startEngine() {
        MasMaxstAR.setLicenseKey("AQZNsxxQWPWzyhupVRSttvVXGuHxsMV2pRs/n75JqUo=")
        
        openCamera()
        setStatusBarOrientaionChange()
       
        let blocksTrackerMapPath:String = Bundle.main.path(forResource: "Blocks", ofType: "2dmap", inDirectory: "data/SDKSample")!
        let glacierTrackerMapPath:String = Bundle.main.path(forResource: "Glacier", ofType: "2dmap", inDirectory: "data/SDKSample")!
        let legoTrackerMapPath:String = Bundle.main.path(forResource: "Lego", ofType: "2dmap", inDirectory: "data/SDKSample")!
        
        self.trackingManager.start(.TRACKER_TYPE_IMAGE)
        self.trackingManager.setTrackingOption(.NORMAL_TRACKING)
        self.trackingManager.addTrackerData(blocksTrackerMapPath)
        self.trackingManager.addTrackerData(glacierTrackerMapPath)
        self.trackingManager.addTrackerData(legoTrackerMapPath)
        self.trackingManager.loadTrackerData()
    }

    @IBAction func switchNormalImage(_ sender: Any) {
        extendSwitch.setOn(false, animated: true)
        multiSwitch.setOn(false, animated: true)
        normalSwitch.setOn(true, animated: true)
        trackingManager.setTrackingOption(.NORMAL_TRACKING)
    }

    @IBAction func switchMultiImage(_ sender: Any) {
        extendSwitch.setOn(false, animated: true)
        multiSwitch.setOn(true, animated: true)
        normalSwitch.setOn(false, animated: true)
        trackingManager.setTrackingOption(.MULTI_TRACKING)
    }

    @IBAction func switchExtendImage(_ sender: Any) {
        extendSwitch.setOn(true, animated: true)
        multiSwitch.setOn(false, animated: true)
        normalSwitch.setOn(false, animated: true)
        trackingManager.setTrackingOption(.EXTENDED_TRACKING)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func pauseAR() {
        trackingManager.stopTracker()
        cameraDevice.stop()
    }
    
    @objc func enterBackgournd() {
        pauseAR()
    }
    
    @objc func resumeAR() {
        trackingManager.start(.TRACKER_TYPE_IMAGE)
        openCamera()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setOrientaionChange()
    }
    
    func setOrientaionChange() {
        if UIDevice.current.orientation == UIDeviceOrientation.portrait {
            screenSizeWidth = Float(UIScreen.main.nativeBounds.size.width)
            screenSizeHeight = Float(UIScreen.main.nativeBounds.size.height)
            MasMaxstAR.setScreenOrientation(.PORTRAIT_UP)
        } else if UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown {
            screenSizeWidth = Float(UIScreen.main.nativeBounds.size.width)
            screenSizeHeight = Float(UIScreen.main.nativeBounds.size.height)
            MasMaxstAR.setScreenOrientation(.PORTRAIT_DOWN)
        } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
            screenSizeWidth = Float(UIScreen.main.nativeBounds.size.height)
            screenSizeHeight = Float(UIScreen.main.nativeBounds.size.width)
            MasMaxstAR.setScreenOrientation(.LANDSCAPE_LEFT)
        } else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            screenSizeWidth = Float(UIScreen.main.nativeBounds.size.height)
            screenSizeHeight = Float(UIScreen.main.nativeBounds.size.width)
            MasMaxstAR.setScreenOrientation(.LANDSCAPE_RIGHT)
        }
        
        MasMaxstAR.onSurfaceChanged(Int32(screenSizeWidth), height: Int32(screenSizeHeight))
    }
    
    func setStatusBarOrientaionChange() {
        let orientation:UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        
        if orientation == UIInterfaceOrientation.portrait {
            screenSizeWidth = Float(UIScreen.main.nativeBounds.size.width)
            screenSizeHeight = Float(UIScreen.main.nativeBounds.size.height)
            MasMaxstAR.setScreenOrientation(.PORTRAIT_UP)
        } else if orientation == UIInterfaceOrientation.portraitUpsideDown {
            screenSizeWidth = Float(UIScreen.main.nativeBounds.size.width)
            screenSizeHeight = Float(UIScreen.main.nativeBounds.size.height)
            MasMaxstAR.setScreenOrientation(.PORTRAIT_DOWN)
        } else if orientation == UIInterfaceOrientation.landscapeLeft {
            screenSizeWidth = Float(UIScreen.main.nativeBounds.size.height)
            screenSizeHeight = Float(UIScreen.main.nativeBounds.size.width)
            MasMaxstAR.setScreenOrientation(.LANDSCAPE_RIGHT)
        } else if orientation == UIInterfaceOrientation.landscapeRight {
            screenSizeWidth = Float(UIScreen.main.nativeBounds.size.height)
            screenSizeHeight = Float(UIScreen.main.nativeBounds.size.width)
            MasMaxstAR.setScreenOrientation(.LANDSCAPE_LEFT)
        }
        
        MasMaxstAR.onSurfaceChanged(Int32(screenSizeWidth), height: Int32(screenSizeHeight))
    }
}
