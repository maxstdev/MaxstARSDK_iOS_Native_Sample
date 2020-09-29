//
//  MarkerViewController.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2018. 3. 15..
//  Copyright © 2018년 Maxst. All rights reserved.
//

import UIKit
import GLKit
import MaxstARSDKFramework

class MarkerViewController: GLKViewController {

    var cameraDevice:MasCameraDevice = MasCameraDevice()
    var trackingManager:MasTrackerManager = MasTrackerManager()
    var cameraResultCode:MasResultCode = MasResultCode.CameraPermissionIsNotResolved
    
    var backgroundCameraQuad:BackgroundCameraQuad?
    var textureCube:TextureCube = TextureCube()
    
    var screenSizeWidth:Float = 0.0
    var screenSizeHeight:Float = 0.0
    
    @IBOutlet var markerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let maxstAR_cubePath = Bundle.main.path(forResource: "MaxstAR_Cube", ofType: "png", inDirectory: "data/Texture")!
        let maxst_CubeImage = UIImage(contentsOfFile: maxstAR_cubePath)!
        textureCube.setTexture(image: maxst_CubeImage)
        
        trackingManager.setTrackingOption(.NORMAL_TRACKING)
        
        preferredFramesPerSecond = 60
        
        setupGL()
        
        let glKitView:GLKView = self.view as! GLKView

        backgroundCameraQuad = BackgroundCameraQuad(context: glKitView.context)
        startEngine()
        
        NotificationCenter.default.addObserver(self, selector: #selector(pauseAR), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackgournd), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeAR), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pauseAR()
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
        
        self.trackingManager.start(.TRACKER_TYPE_MARKER)
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
        
        var recogMarkerID:String = "Recognized Marker ID : "
        if trackingCount > 0 {
            for i in stride(from: 0, to: trackingCount, by: 1) {
                let trackable:MasTrackable = result.getTrackable(i)
                
                recogMarkerID = recogMarkerID + trackable.getId() + ", "
                textureCube.setProjectionMatrix(projectionMatrix: projectionMatrix)
                textureCube.setPoseMatrix(poseMatrix: trackable.getPose())
                textureCube.setTranslation(x: 0.0, y: 0.0, z: -0.05)
                textureCube.setScale(x: 1.0, y: 1.0, z: 0.1)
                textureCube.draw()
            }
        }
        glDisable(GLenum(GL_DEPTH_TEST))
        
        DispatchQueue.main.async {
            self.markerLabel.text = recogMarkerID
        }
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
        trackingManager.start(.TRACKER_TYPE_MARKER)
        openCamera()
    }
    
    @IBAction func clickedNormal(_ sender: Any) {
        trackingManager.setTrackingOption(.NORMAL_TRACKING)
    }
    
    @IBAction func clickedEnhanced(_ sender: Any) {
        trackingManager.setTrackingOption(.ENHANCED_TRACKING)
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
