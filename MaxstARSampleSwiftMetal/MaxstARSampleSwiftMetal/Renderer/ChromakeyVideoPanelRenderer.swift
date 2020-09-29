//
//  ChromakeyVideoPanelRenderer.swift
//  MaxstARSampleSwiftMetal
//
//  Created by Kimseunglee on 2018. 3. 15..
//  Copyright © 2018년 Maxst. All rights reserved.
//

import UIKit
import MetalKit
import Metal
import MaxstARSDKFramework

class ChromakeyVideoPanelRenderer: BaseModel {
    var vertexData:[Vertex]?
    var vertexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    
    var width:Int = 0
    var height:Int = 0
    
    var samplerState:MTLSamplerState!
    
    let A = Vertex(x: -0.5, y:   0.5, z:   0.0, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 0, t: 1)
    let B = Vertex(x: -0.5, y:  -0.5, z:   0.0, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 0, t: 0)
    let C = Vertex(x:  0.5, y:  -0.5, z:   0.0, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 1, t: 0)
    let D = Vertex(x:  0.5, y:   0.5, z:   0.0, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 1, t: 1)
    
    var verticesArray:Array<Vertex>?
    
    required init(device:MTLDevice!) {
        super.init()
        self.device = device
        
        verticesArray = [
            A,B,C,C,D,A,
        ]
        setup()
    }
    
    func setVideoSize(width:Int, height:Int) {
        self.width = width
        self.height = height
    }
    
    func setup() {
        let dataSize = verticesArray!.count * MemoryLayout<Vertex>.size
        vertexBuffer = device!.makeBuffer(bytes: verticesArray!, length: dataSize, options: [])
        uniformBuffer = device!.makeBuffer(length: MemoryLayout<matrix_float4x4>.size, options: [])
        
        let library = device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "chromakey_vertex_func")
        let frag_func = library.makeFunction(name: "chromakey_fragment_func")
        
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        rpld.fragmentFunction = frag_func
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        rpld.depthAttachmentPixelFormat = .depth32Float
        
        rpld.colorAttachments[0].isBlendingEnabled = true
        rpld.colorAttachments[0].rgbBlendOperation = .add
        rpld.colorAttachments[0].alphaBlendOperation = .add
        
        rpld.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        rpld.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        
        rpld.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        rpld.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            try rps = device!.makeRenderPipelineState(descriptor: rpld)
        } catch let error {
            NSLog("fail")
            print("\(error)")
        }
        
        let depthStateDesc:MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStateDesc.depthCompareFunction = .less
        depthStateDesc.isDepthWriteEnabled = true
        
        depthStencilState = self.device!.makeDepthStencilState(descriptor: depthStateDesc)
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.rAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.normalizedCoordinates = true
        
        samplerState = device!.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    func draw(commandEncoder:MTLRenderCommandEncoder, videoTextureId:MTLTexture!)
    {
        if self.width == 0 || self.height == 0 || videoTextureId == nil
        {
            return;
        }
        
        commandEncoder.setRenderPipelineState(self.rps!)
        commandEncoder.setDepthStencilState(self.depthStencilState)
        
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentTexture(videoTextureId, index: 0)
        
        self.localMVPMatrix = matrix_multiply(self.projectionMatrix, self.modelMatrix)
        
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: localMVPMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
        
        if let samplerState = samplerState {
            commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        }
        let vertexCount = verticesArray!.count
        
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
    }
}

