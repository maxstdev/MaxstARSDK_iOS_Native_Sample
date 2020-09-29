//
//  ObjectTrackerViewController.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 12..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import MaxstARSDKFramework

class ObjectFusionTrackerViewController: UIViewController, MTKViewDelegate {
    public var fileName:String?
    
    var cameraDevice:MasCameraDevice = MasCameraDevice()
    var trackingManager:MasTrackerManager = MasTrackerManager()
    var cameraResultCode:MasResultCode = MasResultCode.CameraPermissionIsNotResolved
    
    var textureCube:TextureCube! = nil
    var backgroundCameraQuad:BackgroundCameraQuad?
    var featurePoint:FeaturePoint! = nil
    var boundingBox:BoundingBox! = nil
    
    
    var screenSizeWidth:Float = 0.0
    var screenSizeHeight:Float = 0.0
    var worldTranslationPosition:vector_float3 = vector_float3(0.0, 0.0, 0.0)
    
    @IBOutlet var metalView: MTKView!
    var commandQueue:MTLCommandQueue?
    var device:MTLDevice!
    
    @IBOutlet weak var guideView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupMetal()
        
        let maxstAR_cubePath = Bundle.main.path(forResource: "MaxstAR_Cube", ofType: "png", inDirectory: "data/Texture")!
        let maxst_CubeImage = UIImage(contentsOfFile: maxstAR_cubePath)!
        textureCube?.setTexture(textureImage: maxst_CubeImage)
        
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
    
    func setupMetal() {
        self.metalView?.delegate = self
        self.metalView?.device = MTLCreateSystemDefaultDevice()!
        self.device = self.metalView?.device
        self.commandQueue = device!.makeCommandQueue()
        
        textureCube = TextureCube(device: self.device)
        backgroundCameraQuad = BackgroundCameraQuad(device: self.device)
        featurePoint = FeaturePoint(device: self.device)
        boundingBox = BoundingBox(device: self.device)
        
        let bluedotPath = Bundle.main.path(forResource: "bluedot", ofType: "png", inDirectory: "data/Texture")!
        let blueImage = UIImage(contentsOfFile: bluedotPath)!
        let reddotPath = Bundle.main.path(forResource: "reddot", ofType: "png", inDirectory: "data/Texture")!
        let redImage = UIImage(contentsOfFile: reddotPath)!
        featurePoint.setFeatureImage(blueImage: blueImage, redImage: redImage)
        featurePoint.setTrackingState(tracked: true)
        
        screenSizeWidth = Float(UIScreen.main.nativeBounds.size.width)
        screenSizeHeight = Float(UIScreen.main.nativeBounds.size.height)
        
        MasMaxstAR.onSurfaceChanged(Int32(screenSizeWidth), height: Int32(screenSizeHeight))
    }
    
    func startEngine() {
        MasMaxstAR.setLicenseKey("AQZNsxxQWPWzyhupVRSttvVXGuHxsMV2pRs/n75JqUo=")
        setStatusBarOrientaionChange()
        
        if(trackingManager.isFusionSupported()) {
            cameraDevice.setFusionEnable()
            cameraResultCode = cameraDevice.start(0, width: 1920, height: 1440)
            trackingManager.start(.TRACKER_TYPE_OBJECT_FUSION)
            let objectTrackerMapPath:String = Bundle.main.path(forResource: "obj_1031_3", ofType: "3dmap", inDirectory: "data/SDKSample")!
            trackingManager.addTrackerData(objectTrackerMapPath)
            trackingManager.addTrackerData("{\"object_fusion\":\"set_length\",\"object_name\":\"obj_1031_3\", \"length\":0.198}");
            trackingManager.loadTrackerData()
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
            let guideInfo:MasGuideInfo! = trackingManager.getGuideInformation()
            let fusionState = trackingManager.getFusionTrackingState()
            
            let backgroundImage:MasTrackedImage = trackingState.getImage()
            let backgroundProjectionMatrix:matrix_float4x4 = cameraDevice.getBackgroundPlaneProjectionMatrix()

            let projectionMatrix:matrix_float4x4 = cameraDevice.getProjectionMatrix()
        
            if let cameraQuad = backgroundCameraQuad {
                cameraQuad.setProjectionMatrix(projectionMatrix: backgroundProjectionMatrix)
                cameraQuad.draw(commandEncoder: commandEncoder, image: backgroundImage)
            }
            
            featurePoint.draw(commandEncoder: commandEncoder, trackingManager: trackingManager, projectionMatrix: projectionMatrix)
            
            if fusionState == 1 {
                DispatchQueue.main.async {
                    self.guideView.isHidden = true
                }
            } else {
                DispatchQueue.main.async {
                    self.guideView.isHidden = false
                }
            }

            let trackingCount:Int32 = result.getCount()
            
            if(trackingCount > 0 && fusionState == 1) {
                let trackable:MasTrackable = result.getTrackable(0)
                let poseMatrix:matrix_float4x4 = trackable.getPose()
                
                textureCube.setProjectionMatrix(projectionMatrix: projectionMatrix)
                textureCube.setPoseMatrix(poseMatrix: poseMatrix)
                textureCube.setTranslation(x: 0.0, y: 0.0, z: -0.15)
                textureCube.setScale(x: 0.3, y: 0.3, z: 0.3)
                textureCube.draw(commandEncoder: commandEncoder)
                
                if(guideInfo != nil) {
                    let anchors = guideInfo.getTagAnchors()
                    if anchors != nil {
                        for eachAnchor in anchors! {
                            let anchor = eachAnchor as! MasTagAnchor
                            let pin:PinRenderer = PinRenderer(device: self.device, color: UIColor.red)
                            pin.setProjectionMatrix(projectionMatrix: projectionMatrix)
                            pin.setPoseMatrix(poseMatrix: poseMatrix)
                            pin.setTranslation(x: anchor.getPosition().x, y: anchor.getPosition().y, z: anchor.getPosition().z)
                            pin.setRotation(x: degreesToRadians(degree: -90), y: 0, z: 0)
                            pin.setScale(x: 0.02, y: 0.02, z: 0.02)
                            pin.draw(commandEncoder: commandEncoder)
                        }
                    }
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
        trackingManager.stopTracker()
        cameraDevice.stop()
    }
    
    @objc func enterBackgournd() {
        pauseAR()
    }
    
    @objc func resumeAR() {
        if(trackingManager.isFusionSupported()) {
            cameraDevice.setFusionEnable()
            cameraResultCode = cameraDevice.start(0, width: 1920, height: 1440)
            trackingManager.start(.TRACKER_TYPE_OBJECT_FUSION)
        }
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
