//
//  ImageTrackerViewController.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 12..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import GLKit
import MaxstARSDKFramework
import MaxstVideoFramework

class ImageTrackerViewController: GLKViewController {
    
    @IBOutlet var normalSwitch: UISwitch!
    @IBOutlet var multiSwitch: UISwitch!
    @IBOutlet var extendSwitch: UISwitch!
    @IBOutlet var testImageView: UIImageView!
    
    var cameraDevice:MasCameraDevice = MasCameraDevice()
    var trackingManager:MasTrackerManager = MasTrackerManager()
    var cameraResultCode:MasResultCode = MasResultCode.CameraPermissionIsNotResolved
    
    var backgroundCameraQuad:BackgroundCameraQuad?
    var textureCube:TextureCube = TextureCube()
    var coloredCube:ColorCube = ColorCube()
    var videoPanelRenderer:VideoPanelRenderer = VideoPanelRenderer()
    var chromakeyVideoPanelRenderer:ChromakeyVideoPanelRenderer = ChromakeyVideoPanelRenderer()
    
    var videoCaptureController:VideoCaptureController = VideoCaptureController()
    var chromakeyVideoCaptureController:VideoCaptureController = VideoCaptureController()
    var screenSizeWidth:Float = 0.0
    var screenSizeHeight:Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendSwitch.setOn(false, animated: false)
        multiSwitch.setOn(false, animated: false)
        normalSwitch.setOn(true, animated: false)
        
        
        let moviePath1 = Bundle.main.path(forResource: "VideoSample", ofType: "mp4", inDirectory: "data/Video")!
        let moviePath2 = Bundle.main.path(forResource: "ShutterShock", ofType: "mp4", inDirectory: "data/Video")!
        let maxstAR_cubePath = Bundle.main.path(forResource: "MaxstAR_Cube", ofType: "png", inDirectory: "data/Texture")!
        
        let maxst_CubeImage = UIImage(contentsOfFile: maxstAR_cubePath)!
        textureCube.setTexture(image: maxst_CubeImage)

        trackingManager.setTrackingOption(.NORMAL_TRACKING)
        
        preferredFramesPerSecond = 60
        
        setupGL()
        
        let glKitView:GLKView = self.view as! GLKView
        videoCaptureController.open(moviePath1, repeat: true, isMetal: false, context:glKitView.context)
        chromakeyVideoCaptureController.open(moviePath2, repeat: true, isMetal: false, context:glKitView.context)
        videoPanelRenderer.setVideoSize(width: Int(videoCaptureController.getVideoWidth()), height: Int(videoCaptureController.getVideoHeight()))
        chromakeyVideoPanelRenderer.setVideoSize(width: Int(chromakeyVideoCaptureController.getVideoWidth()), height: Int(chromakeyVideoCaptureController.getVideoHeight()))
        
        backgroundCameraQuad = BackgroundCameraQuad(context: glKitView.context)
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
    
    func setupGL() {
        let glKitView:GLKView = self.view as! GLKView
        glKitView.context = EAGLContext.init(api: EAGLRenderingAPI.openGLES2)!
        glKitView.drawableColorFormat = GLKViewDrawableColorFormat.RGBA8888
        glKitView.drawableDepthFormat = GLKViewDrawableDepthFormat.format24
        
        EAGLContext.setCurrent(glKitView.context)
        glClearColor(0, 0, 0, 1)
        
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
    
    func startEngine() {
        
        MasMaxstAR.setLicenseKey("JtAS1fT5r67/NJpU4YdYY57SmgEkr9gw7pJH1SrBniU=")
        
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

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glViewport(0, 0, GLsizei(screenSizeWidth), GLsizei(screenSizeHeight))
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT))
        
        let trackingState:MasTrackingState = trackingManager.updateTrackingState()
        let result:MasTrackingResult = trackingState.getTrackingResult()
        
        let backgroundImage:MasTrackedImage = trackingState.getImage()
        let backgroundProjectionMatrix:matrix_float4x4 = cameraDevice.getBackgroundPlaneProjectionMatrix()

        glEnable(GLenum(GL_DEPTH_TEST))
        
        let projectionMatrix:matrix_float4x4 = cameraDevice.getProjectionMatrix()
        
        if let cameraQuad = backgroundCameraQuad {
            cameraQuad.draw(image:backgroundImage, projectionMatrix: backgroundProjectionMatrix)
        }
        
        let trackingCount:Int32 = result.getCount()
        
        if trackingCount > 0 {
            for i in stride(from: 0, to: trackingCount, by: 1) {
                let trackable:MasTrackable = result.getTrackable(i)
                
                if trackable.getName() == "Lego" {
                    if videoCaptureController.getState() == MEDIA_STATE.PLAYING {
                        videoCaptureController.play()
                        videoCaptureController.update()
                        
                        videoPanelRenderer.setProjectionMatrix(projectionMatrix: projectionMatrix)
                        videoPanelRenderer.setPoseMatrix(poseMatrix: trackable.getPose())
                        videoPanelRenderer.setTranslation(x: 0.0, y: 0.0, z: 0.0)
                        videoPanelRenderer.setScale(x: 0.26, y: 0.15, z: 1.0)
                        videoPanelRenderer.draw(videoTextureId: videoCaptureController.getOpenglesTextureId())
                    }
                } else if trackable.getName() == "Blocks" {
                    if chromakeyVideoCaptureController.getState() == MEDIA_STATE.PLAYING {
                        chromakeyVideoCaptureController.play()
                        chromakeyVideoCaptureController.update()
                        
                        chromakeyVideoPanelRenderer.setProjectionMatrix(projectionMatrix: projectionMatrix)
                        chromakeyVideoPanelRenderer.setPoseMatrix(poseMatrix: trackable.getPose())
                        chromakeyVideoPanelRenderer.setTranslation(x: 0.0, y: 0.0, z: 0.0)
                        chromakeyVideoPanelRenderer.setScale(x: 0.26, y: 0.18, z: 1.0)
                        chromakeyVideoPanelRenderer.draw(videoTextureId: chromakeyVideoCaptureController.getOpenglesTextureId())
                    }
                } else if trackable.getName() == "Glacier" {
                    textureCube.setProjectionMatrix(projectionMatrix: projectionMatrix)
                    textureCube.setPoseMatrix(poseMatrix: trackable.getPose())
                    textureCube.setTranslation(x: 0.0, y: 0.0, z: -0.025)
                    textureCube.setScale(x: 0.15, y: 0.15, z: 0.05)
                    textureCube.draw()
                } else {
                    coloredCube.setProjectionMatrix(projectionMatrix: projectionMatrix)
                    coloredCube.setPoseMatrix(poseMatrix: trackable.getPose())
                    coloredCube.setTranslation(x: 0.0, y: 0.0, z: -0.025)
                    coloredCube.setScale(x: 0.15, y: 0.15, z: 0.005)
                    coloredCube.draw()
                }
            }
        }
        else {
            videoCaptureController.pause()
            chromakeyVideoCaptureController.pause()
        }
        
        glDisable(GLenum(GL_DEPTH_TEST))
        
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
