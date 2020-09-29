//
//  FeaturePointCPU.swift
//  MaxstARSampleSwiftMetal
//
//  Created by Kimseunglee on 2018. 3. 14..
//  Copyright © 2018년 Maxst. All rights reserved.
//

import UIKit
import MetalKit
import simd
import MaxstARSDKFramework

class FeaturePoint: NSObject {
    var device: MTLDevice?
    var rps: MTLRenderPipelineState?
    
    var vertexData:[FeatureVertex] = [FeatureVertex].init(repeating: FeatureVertex(x: 0,y: 0,z: 0,s: 0,t: 0), count: 2000*6)
    //var indexData:[u_short] = [u_short].init(repeating: 0, count: 2000*3*2)
    
    var vertexBuffer: MTLBuffer!
    //var indexBuffer: MTLBuffer!
    var uniformBuffer: MTLBuffer!
    
    var blueTexture: MTLTexture!
    var redTexture: MTLTexture!
    var samplerState:MTLSamplerState!
    
    var trackingState:Bool = false
    var featureSize:Float = 0.01
    
    var localMVPMatrix:matrix_float4x4!  = matrix_identity_float4x4
    var modelMatrix:matrix_float4x4!  = matrix_identity_float4x4
    
    required init(device:MTLDevice!) {
        super.init()
        
        self.device = device
        
        setup()
    }
    
    func setTrackingState(tracked:Bool) {
        self.trackingState = tracked
    }
    
    func setFeatureImage(blueImage:UIImage!, redImage:UIImage!) {
        let textureLoader = MTKTextureLoader(device: device!)
        blueTexture = try! textureLoader.newTexture(cgImage: blueImage!.cgImage!, options: [MTKTextureLoader.Option.SRGB:false])
        redTexture = try! textureLoader.newTexture(cgImage: redImage.cgImage!, options: [MTKTextureLoader.Option.SRGB:false])
    }
    
    func setup() {
        let vertexDataSize = vertexData.count * MemoryLayout<FeatureVertex>.size
        
        vertexBuffer = device!.makeBuffer(bytes: vertexData, length: vertexDataSize, options: [])
        uniformBuffer = device!.makeBuffer(length: MemoryLayout<matrix_float4x4>.size, options: [])
        
        let library = device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "vertex_feature_point_func")
        let frag_func = library.makeFunction(name: "fragment_feature_point_func")
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        rpld.fragmentFunction = frag_func
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        rpld.depthAttachmentPixelFormat = .depth32Float
        
        rpld.colorAttachments[0].isBlendingEnabled = true
        rpld.colorAttachments[0].alphaBlendOperation = .add
        rpld.colorAttachments[0].rgbBlendOperation = .add
        
        rpld.colorAttachments[0].sourceRGBBlendFactor = .one
        rpld.colorAttachments[0].sourceAlphaBlendFactor = .one
        
        rpld.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        rpld.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            try rps = device!.makeRenderPipelineState(descriptor: rpld)
        } catch let error {
            NSLog("fail")
            print("\(error)")
        }
        
        let samplerDescriptor = MTLSamplerDescriptor()
        
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.normalizedCoordinates = true
        
        samplerState = device!.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    func draw(commandEncoder:MTLRenderCommandEncoder, trackingManager:MasTrackerManager, projectionMatrix:matrix_float4x4)
    {
        guard let guideInfo = trackingManager.getGuideInformation() else {
            return
        }
    
        let featureVertexCount = guideInfo.getGuideFeatureCount()
        let featurePointer = guideInfo.getGuideFeatureBuffer()
        
        if featureVertexCount == 0 {
            return
        }
        
        guard let featurePtr = featurePointer else {
            return
        }

        var vertexPtrCount:Int = 0;
        
        for i:Int in 0..<Int(featureVertexCount) {
            var originalPoint:simd_float3 = simd_make_float3(featurePtr[vertexPtrCount + 0], featurePtr[vertexPtrCount + 1], featurePtr[vertexPtrCount + 2]);
            let vertex0 = FeatureVertex(x:originalPoint.x - featureSize, y:originalPoint.y + featureSize, z:originalPoint.z, s:0.0, t:0.0)
            let vertex1 = FeatureVertex(x:originalPoint.x - featureSize, y:originalPoint.y - featureSize, z:originalPoint.z, s:0.0, t:1.0)
            let vertex2 = FeatureVertex(x:originalPoint.x + featureSize, y:originalPoint.y - featureSize, z:originalPoint.z, s:1.0, t:1.0)
            let vertex3 = FeatureVertex(x:originalPoint.x + featureSize, y:originalPoint.y + featureSize, z:originalPoint.z, s:1.0, t:0.0)
            
            vertexData[6 * i + 0] = vertex0
            vertexData[6 * i + 1] = vertex1
            vertexData[6 * i + 2] = vertex2
            vertexData[6 * i + 3] = vertex0
            vertexData[6 * i + 4] = vertex2
            vertexData[6 * i + 5] = vertex3
            vertexPtrCount += 3;
        }
        
        let vertexPointer = vertexBuffer.contents()
        memcpy(vertexPointer, vertexData, MemoryLayout<FeatureVertex>.size*Int(featureVertexCount)*6)
        
        self.localMVPMatrix = projectionMatrix
        
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: localMVPMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
        
        commandEncoder.setRenderPipelineState(self.rps!)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        
        if trackingState {
            commandEncoder.setFragmentTexture(blueTexture, index: 0)
        } else {
            commandEncoder.setFragmentTexture(redTexture, index: 0)
        }
        
        if let samplerState = samplerState {
            commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        }
        
        let vertexCount = Int(featureVertexCount)*6
        
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
    
    }
}
