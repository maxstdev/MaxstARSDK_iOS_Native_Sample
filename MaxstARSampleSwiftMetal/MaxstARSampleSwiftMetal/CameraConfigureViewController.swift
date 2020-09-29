//
//  CameraConfigureViewController.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 12..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import MaxstARSDKFramework

class CameraConfigureViewController: UIViewController, MTKViewDelegate {
    
    enum CAMERA_DIRECTION:Int {
        case REAR = 0
        case FRONT = 1
    }
    
    var cameraDevice:MasCameraDevice = MasCameraDevice()
    var trackingManager:MasTrackerManager = MasTrackerManager()
    var cameraResultCode:MasResultCode = MasResultCode.CameraPermissionIsNotResolved
    
    var currentCameraDirection:CAMERA_DIRECTION = CAMERA_DIRECTION.REAR
    
    var backgroundCameraQuad:BackgroundCameraQuad?
    var textureCube:TextureCube?
    var screenSizeWidth:Float = 0.0
    var screenSizeHeight:Float = 0.0
    
    @IBOutlet var rearSwitch: UISwitch!
    @IBOutlet var frontSwitch: UISwitch!
    @IBOutlet var flashSwitch: UISwitch!
    @IBOutlet var horizontalSwitch: UISwitch!
    @IBOutlet var verticalSwitch: UISwitch!
    
    @IBOutlet var metalView: MTKView!
    var commandQueue:MTLCommandQueue?
    var device:MTLDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetal()
        let maxstAR_cubePath = Bundle.main.path(forResource: "MaxstAR_Cube", ofType: "png", inDirectory: "data/Texture")!
        let maxst_CubeImage = UIImage(contentsOfFile: maxstAR_cubePath)!
        textureCube?.setTexture(textureImage: maxst_CubeImage)
        
        startEngine()
        
        NotificationCenter.default.addObserver(self, selector: #selector(pauseAR), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackgournd), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeAR), name: UIApplication.didBecomeActiveNotification, object: nil)   // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pauseAR()
        trackingManager.destroyTracker()
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
    
    func setupMetal() {
        self.metalView?.delegate = self
        self.metalView?.device = MTLCreateSystemDefaultDevice()!
        self.device = self.metalView?.device
        self.commandQueue = device!.makeCommandQueue()
        
        backgroundCameraQuad = BackgroundCameraQuad(device: self.device)
        textureCube = TextureCube(device: self.device)
        
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
        MasMaxstAR.setLicenseKey("AQZNsxxQWPWzyhupVRSttvVXGuHxsMV2pRs/n75JqUo=")
        openCamera()
        
        let glacierTrackerMapPath:String = Bundle.main.path(forResource: "Glacier", ofType: "2dmap", inDirectory: "data/SDKSample")!
        
        self.trackingManager.start(.TRACKER_TYPE_IMAGE)
        self.trackingManager.setTrackingOption(.NORMAL_TRACKING)
        self.trackingManager.addTrackerData(glacierTrackerMapPath)
        self.trackingManager.loadTrackerData()
        
        setStatusBarOrientaionChange()
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
            
            let backgroundImage:MasTrackedImage = trackingState.getImage()
            let backgroundProjectionMatrix:matrix_float4x4 = cameraDevice.getBackgroundPlaneProjectionMatrix()
            
            if let cameraQuad = backgroundCameraQuad {
                cameraQuad.setProjectionMatrix(projectionMatrix: backgroundProjectionMatrix)
                cameraQuad.draw(commandEncoder: commandEncoder, image: backgroundImage)
            }
            
            let result:MasTrackingResult = trackingState.getTrackingResult()
            let trackingCount:Int32 = result.getCount()
            let projectionMatrix:matrix_float4x4 = cameraDevice.getProjectionMatrix()
            
            if trackingCount > 0 {
                for i in stride(from: 0, to: trackingCount, by: 1) {
                    let trackable:MasTrackable = result.getTrackable(i)
                    let poseMatrix:matrix_float4x4 = trackable.getPose()
                    
                    textureCube!.setProjectionMatrix(projectionMatrix: projectionMatrix)
                    textureCube!.setPoseMatrix(poseMatrix: poseMatrix)
                    textureCube!.setTranslation(x: 0.0, y: 0.0, z: -trackable.getHeight()*0.25*0.25)
                    textureCube!.setScale(x: trackable.getWidth()*0.25, y: trackable.getHeight()*0.25, z: trackable.getHeight()*0.25*0.5)
                    textureCube!.draw(commandEncoder: commandEncoder)
                }
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
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
        
        if _depthTexture == nil {
            let textureDescriptor:MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: drawable.texture.width, height: drawable.texture.height, mipmapped: false)
            textureDescriptor.storageMode = .private
            textureDescriptor.usage = .renderTarget
            
            _depthTexture = device?.makeTexture(descriptor: textureDescriptor)
        }
        
        renderPass.depthAttachment.texture = _depthTexture
        
        return renderPass
    }
    
    @objc func pauseAR() {
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
