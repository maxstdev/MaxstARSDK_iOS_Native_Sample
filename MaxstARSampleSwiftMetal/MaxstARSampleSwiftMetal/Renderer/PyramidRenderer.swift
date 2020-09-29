//
//  PyramidRenderer.swift
//  MaxstARSampleSwiftMetal
//
//  Created by keane on 25/01/2019.
//  Copyright © 2019 Maxst. All rights reserved.
//

//
//  CubeRenderer.swift
//  MaxstARSampleSwiftMetal
//
//  Created by keane on 25/01/2019.
//  Copyright © 2019 Maxst. All rights reserved.
//

import UIKit
import MetalKit

class PyramidRenderer : BaseModel {
    var positionBuffer: MTLBuffer?
    var colorBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    var samplerState:MTLSamplerState!
    
    let VERTEX_BUF:[Float] = [
        -0.2, -0.5, -0.5,    // 0
        0.2, -0.5, -0.5,        // 1
        0.5, -0.2, -0.5,        // 2
        0.5, 0.2, -0.5,        // 3
        0.2, 0.5, -0.5,        // 4
        -0.2, 0.5, -0.5,        // 5
        -0.5, 0.2, -0.5,        // 6
        -0.5, -0.2, -0.5,    // 7
        0.0, 0.0, 0.5,        // 8
    ]
    
    let INDEX_BUF:[UInt16] = [
        0, 1, 8,
        1, 2, 8,
        2, 3, 8,
        3, 4, 8,
        4, 5, 8,
        5, 6, 8,
        6, 7, 8,
        7, 0, 8
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
    
    required init(device:MTLDevice!, color:UIColor) {
        super.init()
        self.device = device
        setColor(color: color)
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
        rpld.depthAttachmentPixelFormat = .depth32Float
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        depthStencilState = device!.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
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
        commandEncoder.setDepthStencilState(depthStencilState)
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


