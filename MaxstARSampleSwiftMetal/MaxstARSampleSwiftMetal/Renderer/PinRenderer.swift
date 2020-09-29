//
//  PinRenderer.swift
//  VisualSlamTool
//
//  Created by keane on 29/01/2019.
//  Copyright © 2019 maxst. All rights reserved.
//

import UIKit
import simd

class PinRenderer: BaseModel {
    var pinVertexBuffer: MTLBuffer?
    var pinColorBuffer: MTLBuffer?
    var pinIndexBuffer: MTLBuffer?
    
    var uniformBuffer: MTLBuffer!
    var samplerState:MTLSamplerState!
    
    var PIN_VERTEX_BUF:[Float] = [
        0.452477, 1.43869, -0,
        0, 0, 0,
        -0.31995, 1.43869, 0.31995,
        -0.452477, 1.43869, 0,
        0.31995, 1.43869, -0.31995,
        -0.31995, 1.43869, -0.31995,
        0.31995, 1.43869, 0.31995,
        0, 1.43869, 0.452477,
        0, 1.43869, -0.452477,
        0, 2.66178, 0.850651,
        0, 1.61032, 0.850651,
        0.850651, 2.13605, 0.525731,
        0.850651, 2.13605, -0.525731,
        0, 2.66178, -0.850651,
        0, 1.61032, -0.850651,
        -0.850651, 2.13605, -0.525731,
        -0.850651, 2.13605, 0.525731,
        0.525731, 2.9867, 0,
        -0.525731, 2.9867, 0,
        -0.525731, 1.2854, 0,
        0.525731, 1.2854, 0,
        0, 3.13605, 0,
        0.309017, 2.94506, 0.5,
        -0.309017, 2.94506, 0.5,
        0.809017, 2.63605, 0.309017,
        0.5, 2.44506, 0.809017,
        0.809017, 2.63605, -0.309017,
        1, 2.13605, 0,
        0.309017, 2.94506, -0.5,
        0.5, 2.44506, -0.809017,
        -0.309017, 2.94506, -0.5,
        -0.809017, 2.63605, -0.309017,
        -0.5, 2.44506, -0.809017,
        -0.809017, 2.63605, 0.309017,
        -1, 2.13605, 0,
        -0.5, 2.44506, 0.809017,
        0, 1.13605, 0,
        -0.309017, 1.32703, 0.5,
        0.309017, 1.32703, 0.5,
        0.809017, 1.63605, 0.309017,
        0.5, 1.82703, 0.809017,
        0.809017, 1.63605, -0.309017,
        0.5, 1.82703, -0.809017,
        0.309017, 1.32703, -0.5,
        -0.309017, 1.32703, -0.5,
        -0.5, 1.82703, -0.809017,
        -0.809017, 1.63605, -0.309017,
        -0.809017, 1.63605, 0.309017,
        -0.5, 1.82703, 0.809017,
        0, 2.13605, 1,
        0, 2.13605, -1,
        ]
    
    var PIN_INDEX_BUF:[UInt16] = [
        0, 1, 4,
        3, 1, 2,
        7, 1, 6,
        5, 1, 3,
        2, 1, 7,
        4, 1, 8,
        6, 1, 0,
        8, 1, 5,
        23, 21, 18,
        22, 17, 21,
        21, 23, 22,
        9, 22, 23,
        22, 24, 17,
        25, 11, 24,
        24, 22, 25,
        9, 25, 22,
        24, 26, 17,
        27, 12, 26,
        26, 24, 27,
        11, 27, 24,
        26, 28, 17,
        29, 13, 28,
        28, 26, 29,
        12, 29, 26,
        28, 21, 17,
        30, 18, 21,
        21, 28, 30,
        13, 30, 28,
        32, 30, 13,
        31, 18, 30,
        30, 32, 31,
        15, 31, 32,
        34, 31, 15,
        33, 18, 31,
        31, 34, 33,
        16, 33, 34,
        33, 23, 18,
        35, 9, 23,
        23, 33, 35,
        16, 35, 33,
        38, 36, 20,
        37, 19, 36,
        36, 38, 37,
        10, 37, 38,
        40, 39, 11,
        38, 20, 39,
        39, 40, 38,
        10, 38, 40,
        39, 27, 11,
        41, 12, 27,
        27, 39, 41,
        20, 41, 39,
        41, 42, 12,
        43, 14, 42,
        42, 41, 43,
        20, 43, 41,
        43, 44, 14,
        36, 19, 44,
        44, 43, 36,
        20, 36, 43,
        44, 45, 14,
        46, 15, 45,
        45, 44, 46,
        19, 46, 44,
        46, 34, 15,
        47, 16, 34,
        34, 46, 47,
        19, 47, 46,
        47, 48, 16,
        37, 10, 48,
        48, 47, 37,
        19, 37, 47,
        49, 48, 10,
        35, 16, 48,
        48, 49, 35,
        9, 35, 49,
        25, 40, 11,
        49, 10, 40,
        40, 25, 49,
        9, 49, 25,
        29, 50, 13,
        42, 14, 50,
        50, 29, 42,
        12, 42, 29,
        50, 32, 13,
        45, 15, 32,
        32, 50, 45,
        14, 45, 50,
        ]
    
    var PIN_COLOR_BUF:[Float]! = nil
    
    required init(device:MTLDevice!, color:UIColor) {
        super.init()
        self.device = device
        setColor(color: color)
        setup()
    }
    
    func setColor(color:UIColor) {
        let vertexCount =  PIN_VERTEX_BUF.count / 3;
        PIN_COLOR_BUF = Array<Float>.init(repeating: 0.0, count: vertexCount*4)
        
        for i in 0..<vertexCount {
            PIN_COLOR_BUF[i*4+0] = Float(color.rgba.red)
            PIN_COLOR_BUF[i*4+1] = Float(color.rgba.green)
            PIN_COLOR_BUF[i*4+2] = Float(color.rgba.blue)
            PIN_COLOR_BUF[i*4+3] = Float(color.rgba.alpha)
        }
    }
    
    func setup() {
        self.pinVertexBuffer = self.device!.makeBuffer(bytes: PIN_VERTEX_BUF, length: PIN_VERTEX_BUF.count * MemoryLayout<Float>.size, options: [])
        self.pinIndexBuffer = self.device!.makeBuffer(bytes: PIN_INDEX_BUF, length: PIN_INDEX_BUF.count * MemoryLayout<UInt16>.size, options: [])
        self.pinColorBuffer = self.device!.makeBuffer(bytes: PIN_COLOR_BUF, length: PIN_COLOR_BUF.count * MemoryLayout<Float>.size, options: [])
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
        
        commandEncoder.setVertexBuffer(pinVertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(pinColorBuffer, offset: 0, index: 1)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 2)
        
        self.localMVPMatrix = matrix_multiply(self.projectionMatrix, self.modelMatrix)
        
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: localMVPMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
        
        if let samplerState = samplerState {
            commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        }
        
        commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: self.pinIndexBuffer!.length / MemoryLayout<UInt16>.size, indexType: MTLIndexType.uint16, indexBuffer: self.pinIndexBuffer!, indexBufferOffset: 0)
    }
}
