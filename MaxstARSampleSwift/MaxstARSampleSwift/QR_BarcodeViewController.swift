//
//  QR_BarcodeViewController.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 12..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import GLKit
import MaxstARSDKFramework

class QR_BarcodeViewController: GLKViewController {

    @IBOutlet var formatLabel: UILabel!
    @IBOutlet var codeLabel: UILabel!
    
    var cameraDevice:MasCameraDevice = MasCameraDevice()
    var trackingManager:MasTrackerManager = MasTrackerManager()
    var backgroundCameraQuad:BackgroundCameraQuad?
    var cameraResultCode:MasResultCode = MasResultCode.CameraPermissionIsNotResolved
    
    var screenSizeWidth:Float = 0.0
    var screenSizeHeight:Float = 0.0
    
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
        
        trackingManager.start(.TRACKER_TYPE_CODE_SCANNER)
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
        
        glEnable(GLenum(GL_DEPTH_TEST))
        
        let codeScanResult:String = trackingState.getCodeScanResult()
        
        if codeScanResult != "" {
            DispatchQueue.main.async {
                let objectData:Data = codeScanResult.data(using: String.Encoding.utf8)!
                let json = try! JSONSerialization.jsonObject(with: objectData, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: String]
                
                self.formatLabel.text = json["Format"]
                self.codeLabel.text = json["Value"]
            }
        }
        
        glDisable(GLenum(GL_DEPTH_TEST))
    }
    
    @objc func pauseAR() {
        trackingManager.stopTracker()
        cameraDevice.stop()
    }
    
    @objc func enterBackgournd() {
        pauseAR()
    }
    
    @objc func resumeAR() {
        trackingManager.start(.TRACKER_TYPE_CODE_SCANNER)
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
