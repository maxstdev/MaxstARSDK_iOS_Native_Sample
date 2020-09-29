//
//  CubeRenderer.swift
//  MetalTest
//
//  Created by Kimseunglee on 2017. 9. 26..
//  Copyright © 2017년 Maxst. All rights reserved.
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

class Axis : BaseModel {
    var positionBuffer: MTLBuffer?
    var colorBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    var samplerState:MTLSamplerState!
    
    let VERTEX_BUF:[Float] = [
        // y
        -0.01, 0.5, -0.01,
        0.01, 0.5, -0.01,
        0.01, -0.01, -0.01,
        -0.01, -0.01, -0.01,
        -0.01, 0.5, 0.01,
        -0.01, -0.01, 0.01,
        0.01, -0.01, 0.01,
        0.01, 0.5, 0.01,
        
        // x
        -0.01, -0.01, -0.01,
        0.5, -0.01, -0.01,
        0.5, 0.01, -0.01,
        -0.01, 0.01, -0.01,
        -0.01, -0.01, 0.01,
        -0.01, 0.01, 0.01,
        0.5, 0.01, 0.01,
        0.5, -0.01, 0.01,
        
        // z
        -0.01, -0.01, 0.5,
        0.01, -0.01, 0.5,
        0.01, 0.01, 0.5,
        -0.01, 0.01, 0.5,
        -0.01, -0.01, -0.01,
        -0.01, 0.01, -0.01,
        0.01, 0.01, -0.01,
        0.01, -0.01, -0.01,
    ]
    
    let INDEX_BUF:[UInt16] = [
        0 + (8 * 0), 1 + (8 * 0), 2 + (8 * 0),    // 1
        2 + (8 * 0), 3 + (8 * 0), 0 + (8 * 0),
        4 + (8 * 0), 5 + (8 * 0), 6 + (8 * 0),    // 2
        6 + (8 * 0), 7 + (8 * 0), 4 + (8 * 0),
        0 + (8 * 0), 4 + (8 * 0), 7 + (8 * 0),    // 3
        7 + (8 * 0), 1 + (8 * 0), 0 + (8 * 0),
        1 + (8 * 0), 7 + (8 * 0), 6 + (8 * 0),    // 4
        6 + (8 * 0), 2 + (8 * 0), 1 + (8 * 0),
        2 + (8 * 0), 6 + (8 * 0), 5 + (8 * 0),    // 5
        5 + (8 * 0), 3 + (8 * 0), 2 + (8 * 0),
        3 + (8 * 0), 5 + (8 * 0), 4 + (8 * 0),    // 6
        4 + (8 * 0), 0 + (8 * 0), 3 + (8 * 0),
        
        0 + (8 * 2), 1 + (8 * 2), 2 + (8 * 2),
        2 + (8 * 2), 3 + (8 * 2), 0 + (8 * 2),
        4 + (8 * 2), 5 + (8 * 2), 6 + (8 * 2),
        6 + (8 * 2), 7 + (8 * 2), 4 + (8 * 2),
        0 + (8 * 2), 4 + (8 * 2), 7 + (8 * 2),
        7 + (8 * 2), 1 + (8 * 2), 0 + (8 * 2),
        1 + (8 * 2), 7 + (8 * 2), 6 + (8 * 2),
        6 + (8 * 2), 2 + (8 * 2), 1 + (8 * 2),
        2 + (8 * 2), 6 + (8 * 2), 5 + (8 * 2),
        5 + (8 * 2), 3 + (8 * 2), 2 + (8 * 2),
        3 + (8 * 2), 5 + (8 * 2), 4 + (8 * 2),
        4 + (8 * 2), 0 + (8 * 2), 3 + (8 * 2),
        
        0 + (8 * 1), 1 + (8 * 1), 2 + (8 * 1),
        2 + (8 * 1), 3 + (8 * 1), 0 + (8 * 1),
        4 + (8 * 1), 5 + (8 * 1), 6 + (8 * 1),
        6 + (8 * 1), 7 + (8 * 1), 4 + (8 * 1),
        0 + (8 * 1), 4 + (8 * 1), 7 + (8 * 1),
        7 + (8 * 1), 1 + (8 * 1), 0 + (8 * 1),
        1 + (8 * 1), 7 + (8 * 1), 6 + (8 * 1),
        6 + (8 * 1), 2 + (8 * 1), 1 + (8 * 1),
        2 + (8 * 1), 6 + (8 * 1), 5 + (8 * 1),
        5 + (8 * 1), 3 + (8 * 1), 2 + (8 * 1),
        3 + (8 * 1), 5 + (8 * 1), 4 + (8 * 1),
        4 + (8 * 1), 0 + (8 * 1), 3 + (8 * 1),
        ]
    
//    let INDEX_BUF:[UInt16] = [
//        0 + (8 * 0), 1 + (8 * 0), 2 + (8 * 0),    // 1
//        2 + (8 * 0), 3 + (8 * 0), 0 + (8 * 0),
//        4 + (8 * 0), 5 + (8 * 0), 6 + (8 * 0),    // 2
//        6 + (8 * 0), 7 + (8 * 0), 4 + (8 * 0),
//        0 + (8 * 0), 4 + (8 * 0), 7 + (8 * 0),    // 3
//        7 + (8 * 0), 1 + (8 * 0), 0 + (8 * 0),
//        1 + (8 * 0), 7 + (8 * 0), 6 + (8 * 0),    // 4
//        6 + (8 * 0), 2 + (8 * 0), 1 + (8 * 0),
//        2 + (8 * 0), 6 + (8 * 0), 5 + (8 * 0),    // 5
//        5 + (8 * 0), 3 + (8 * 0), 2 + (8 * 0),
//        3 + (8 * 0), 5 + (8 * 0), 4 + (8 * 0),    // 6
//        4 + (8 * 0), 0 + (8 * 0), 3 + (8 * 0),
//
//        0 + (8 * 1), 1 + (8 * 1), 2 + (8 * 1),
//        2 + (8 * 1), 3 + (8 * 1), 0 + (8 * 1),
//        4 + (8 * 1), 5 + (8 * 1), 6 + (8 * 1),
//        6 + (8 * 1), 7 + (8 * 1), 4 + (8 * 1),
//        0 + (8 * 1), 4 + (8 * 1), 7 + (8 * 1),
//        7 + (8 * 1), 1 + (8 * 1), 0 + (8 * 1),
//        1 + (8 * 1), 7 + (8 * 1), 6 + (8 * 1),
//        6 + (8 * 1), 2 + (8 * 1), 1 + (8 * 1),
//        2 + (8 * 1), 6 + (8 * 1), 5 + (8 * 1),
//        5 + (8 * 1), 3 + (8 * 1), 2 + (8 * 1),
//        3 + (8 * 1), 5 + (8 * 1), 4 + (8 * 1),
//        4 + (8 * 1), 0 + (8 * 1), 3 + (8 * 1),
//
//        0 + (8 * 2), 1 + (8 * 2), 2 + (8 * 2),
//        2 + (8 * 2), 3 + (8 * 2), 0 + (8 * 2),
//        4 + (8 * 2), 5 + (8 * 2), 6 + (8 * 2),
//        6 + (8 * 2), 7 + (8 * 2), 4 + (8 * 2),
//        0 + (8 * 2), 4 + (8 * 2), 7 + (8 * 2),
//        7 + (8 * 2), 1 + (8 * 2), 0 + (8 * 2),
//        1 + (8 * 2), 7 + (8 * 2), 6 + (8 * 2),
//        6 + (8 * 2), 2 + (8 * 2), 1 + (8 * 2),
//        2 + (8 * 2), 6 + (8 * 2), 5 + (8 * 2),
//        5 + (8 * 2), 3 + (8 * 2), 2 + (8 * 2),
//        3 + (8 * 2), 5 + (8 * 2), 4 + (8 * 2),
//        4 + (8 * 2), 0 + (8 * 2), 3 + (8 * 2),
//    ]
    
    var COLOR_BUF:[Float] = [
        // y
        0.0, 1.0, 0.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        
        // x
        1.0, 1.0, 1.0, 1.0,
        1.0, 0.0, 0.0, 1.0,
        1.0, 0.0, 0.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 0.0, 0.0, 1.0,
        1.0, 0.0, 0.0, 1.0,
        
        // z
        0.0, 0.0, 1.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        ]
    
    required init(device:MTLDevice!) {
        super.init()
        self.device = device
        setup()
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


