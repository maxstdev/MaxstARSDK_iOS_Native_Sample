//
//  CubeRenderer.swift
//  MaxstARSampleSwiftMetal
//
//  Created by keane on 25/01/2019.
//  Copyright © 2019 Maxst. All rights reserved.
//

import UIKit
import MetalKit

class CubeRenderer : BaseModel {
    var positionBuffer: MTLBuffer?
    var colorBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    var samplerState:MTLSamplerState!
    
    let VERTEX_BUF:[Float] = [
        -0.5, -0.5, -0.5, // 0
        0.5, -0.5, -0.5, // 1
        0.5, 0.5, -0.5, // 2
        -0.5, 0.5, -0.5, // 3
        -0.5, -0.5, 0.5, // 4
        0.5, -0.5, 0.5,// 5
        0.5, 0.5, 0.5, // 6
        -0.5, 0.5, 0.5 // 7
    ]
    
    let INDEX_BUF:[UInt16] = [
        0, 2, 3, 2, 0, 1, // back face
        0, 7, 4, 7, 0, 3, // left face
        1, 6, 2, 6, 1, 5, // right face
        0, 5, 1, 5, 0, 4, // bottom face
        3, 6, 7, 6, 3, 2, // up face
        4, 6, 5, 6, 4, 7, // front face
    ]
    
    var COLOR_BUF:[Float] = [
        1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        0.0, 0.0, 0.0, 1.0,
        0.0, 0.0, 0.0, 1.0,
        0.0, 0.0, 0.0, 1.0,
        0.0, 0.0, 0.0, 1.0,
        ]

    required init(device:MTLDevice!, color:UIColor?) {
        super.init()
        self.device = device
        
        if color != nil {
            setColor(color: color!)
        }
        
        setup()
    }
    
    func setColor(color:UIColor) {
        let vertexCount =  VERTEX_BUF.count / 3;
        COLOR_BUF = Array<Float>.init(repeating: 0.0, count: vertexCount*4)

        for i in 0..<vertexCount {
            COLOR_BUF[i*4+0] = Float(color.rgba.red)
            COLOR_BUF[i*4+1] = Float(color.rgba.green)
            COLOR_BUF[i*4+2] = Float(color.rgba.blue)
            COLOR_BUF[i*4+3] = Float(color.rgba.alpha)
        }
    }
    
    func setup() {
        self.positionBuffer = self.device!.makeBuffer(bytes: VERTEX_BUF, length: VERTEX_BUF.count * MemoryLayout<Float>.size, options: [])
        self.indexBuffer = self.device!.makeBuffer(bytes: INDEX_BUF, length: INDEX_BUF.count * MemoryLayout<UInt16>.size, options: [])
        self.colorBuffer = self.device!.makeBuffer(bytes: COLOR_BUF, length: COLOR_BUF.count * MemoryLayout<Float>.size, options: [])
        uniformBuffer = device!.makeBuffer(length: MemoryLayout<matrix_float4x4>.size, options: [])
        
        let library = device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "bounding_box_vertex_func")
        let frag_func = library.makeFunction(name: "bounding_box_fragment_func")
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        rpld.fragmentFunction = frag_func
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            try rps = device!.makeRenderPipelineState(descriptor: rpld)
        } catch let error {
            NSLog("fail")
            print("\(error)")
        }
        
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
    
    func draw(commandEncoder:MTLRenderCommandEncoder)
    {
        commandEncoder.setRenderPipelineState(self.rps!)
        commandEncoder.setDepthStencilState(self.depthStencilState)
        
        commandEncoder.setVertexBuffer(positionBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(colorBuffer, offset: 0, index: 1)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 2)
        
        self.localMVPMatrix = matrix_multiply(self.projectionMatrix, self.modelMatrix)
        
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: localMVPMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
        
        if let samplerState = samplerState {
            commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        }
        
        commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: self.indexBuffer!.length / MemoryLayout<UInt16>.size, indexType: MTLIndexType.uint16, indexBuffer: self.indexBuffer!, indexBufferOffset: 0)
    }
}


