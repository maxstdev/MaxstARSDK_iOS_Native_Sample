//
//  CameraConfigureViewController.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 12..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import GLKit
import MaxstARSDKFramework

class CameraConfigureViewController: GLKViewController {
    
    enum CAMERA_DIRECTION:Int {
        case REAR = 0
        case FRONT = 1
    }
    
    var cameraDevice:MasCameraDevice = MasCameraDevice()
    var cameraResultCode:MasResultCode = MasResultCode.CameraPermissionIsNotResolved
    var backgroundCameraQuad:BackgroundCameraQuad?
    var trackingManager:MasTrackerManager = MasTrackerManager()
    
    var currentCameraDirection:CAMERA_DIRECTION = CAMERA_DIRECTION.REAR
    var screenSizeWidth:Float = 0.0
    var screenSizeHeight:Float = 0.0
    
    @IBOutlet var rearSwitch: UISwitch!
    @IBOutlet var frontSwitch: UISwitch!
    @IBOutlet var flashSwitch: UISwitch!
    @IBOutlet var horizontalSwitch: UISwitch!
    @IBOutlet var verticalSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredFramesPerSecond = 60
        
        setupGL()
        
        let glKitView:GLKView = self.view as! GLKView
        backgroundCameraQuad = BackgroundCameraQuad(context: glKitView.context)
        
        startEngine()
        
        NotificationCenter.default.addObserver(self, selector: #selector(pauseAR), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackgournd), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeAR), name: UIApplication.didBecomeActiveNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pauseAR()
        MasMaxstAR.deinit()
        
        NotificationCenter.default.removeObserver(self)
    }
    @IBAction func switchDirectionRear(_ sender: Any) {
        self.rearSwitch.setOn(true, animated: true)
        self.frontSwitch.setOn(false, animated: true)
        
        if currentCameraDirection == CAMERA_DIRECTION.FRONT {
            currentCameraDirection = CAMERA_DIRECTION.REAR
            openCamera()
        }
    }
    
    @IBAction func switchDirectionFront(_ sender: Any) {
        self.rearSwitch.setOn(false, animated: true)
        self.frontSwitch.setOn(true, animated: true)
        
        if currentCameraDirection == CAMERA_DIRECTION.REAR {
            currentCameraDirection = CAMERA_DIRECTION.FRONT
            openCamera()
            
            if self.flashSwitch.isOn {
                self.flashSwitch.setOn(false, animated: true)
            }
        }
    }
    
    @IBAction func switchFlash(_ sender: Any) {
        if self.frontSwitch.isOn {
            self.flashSwitch.setOn(false, animated: true)
        } else {
            cameraDevice.setFlashLightMode(self.flashSwitch.isOn)
        }
    }
    
    @IBAction func switchFlipHorizontal(_ sender: Any) {
        cameraDevice.flipVideo(MasFlipDirection.HORIZONTAL, toggle: self.horizontalSwitch.isOn)
    }
    
    @IBAction func switchFlipVertical(_ sender: Any) {
        cameraDevice.flipVideo(MasFlipDirection.VERTICAL, toggle: self.verticalSwitch.isOn)
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
        cameraDevice.stop()
        let userDefaults:UserDefaults = UserDefaults.standard
        var resolution:Int = userDefaults.integer(forKey: "CameraResolution")
        
        if resolution == 0 {
            resolution = 640
            userDefaults.set(640, forKey: "CameraResolution")
        }
        
        if resolution == 1280 {
            cameraResultCode = cameraDevice.start(Int32(currentCameraDirection.rawValue), width: 1280, height: 720)
        } else if resolution == 640 {
            cameraResultCode = cameraDevice.start(Int32(currentCameraDirection.rawValue), width: 640, height: 480)
        } else if resolution == 1920 {
            cameraResultCode = cameraDevice.start(Int32(currentCameraDirection.rawValue), width: 1920, height: 1080)
        }
    }
    
    func startEngine() {
        MasMaxstAR.setLicenseKey("JtAS1fT5r67/NJpU4YdYY57SmgEkr9gw7pJH1SrBniU=")
        openCamera()
        setStatusBarOrientaionChange()
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        
        glViewport(0, 0, GLsizei(screenSizeWidth), GLsizei(screenSizeHeight))
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT))
        
        let trackingState:MasTrackingState = trackingManager.updateTrackingState()
        let backgroundImage:MasTrackedImage = trackingState.getImage()
        let backgroundProjectionMatrix:matrix_float4x4 = cameraDevice.getBackgroundPlaneProjectionMatrix()
        
        if let cameraQuad = backgroundCameraQuad {
            cameraQuad.draw(image:backgroundImage, projectionMatrix: backgroundProjectionMatrix)
        }
    }
    
    @objc func pauseAR() {
        cameraDevice.stop()
    }
    
    @objc func enterBackgournd() {
        pauseAR()
    }
    
    @objc func resumeAR() {
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
