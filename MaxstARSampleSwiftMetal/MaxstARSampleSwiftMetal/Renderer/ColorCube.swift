//
//  CubeRenderer.swift
//  MetalTest
//
//  Created by Kimseunglee on 2017. 9. 26..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import MetalKit

class ColorCube : BaseModel {
    var vertexData:[Vertex]?
    var vertexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    var samplerState:MTLSamplerState!

    let A0 = Vertex(x: -0.5, y:  -0.5, z:  -0.5, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 0.0, t: 0.0)
    let A1 = Vertex(x:  0.5, y:  -0.5, z:  -0.5, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 0.0, t: 0.0)
    let A2 = Vertex(x:  0.5, y:   0.5, z:  -0.5, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 0.0, t: 0.0)
    let A3 = Vertex(x: -0.5, y:   0.5, z:  -0.5, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 0.0, t: 0.0)
    let A4 = Vertex(x: -0.5, y:  -0.5, z:   0.5, r:  0.0, g:  0.0, b:  0.0, a:  1.0, s: 0.0, t: 0.0)
    let A5 = Vertex(x:  0.5, y:  -0.5, z:   0.5, r:  0.0, g:  0.0, b:  0.0, a:  1.0, s: 0.0, t: 0.0)
    let A6 = Vertex(x:  0.5, y:   0.5, z:   0.5, r:  0.0, g:  0.0, b:  0.0, a:  1.0, s: 0.0, t: 0.0)
    let A7 = Vertex(x: -0.5, y:   0.5, z:   0.5, r:  0.0, g:  0.0, b:  0.0, a:  1.0, s: 0.0, t: 0.0)
    
    // 2
    var verticesArray:Array<Vertex>?
    
    required init(device:MTLDevice!) {
        super.init()
        
        self.device = device

        verticesArray = [
            A0,A2,A3 ,A2,A0,A1,   //Front
            A0,A7,A4 ,A7,A0,A3,   //Left
            A1,A6,A2 ,A6,A1,A5,   //Right
            A0,A5,A1 ,A5,A0,A4,   //Top
            A3,A6,A7 ,A6,A3,A2,   //Bot
            A4,A6,A5 ,A6,A4,A7    //Back
        ]
        setup()
    }
    
    func setup() {
    
        let dataSize = verticesArray!.count * MemoryLayout<Vertex>.size
        vertexBuffer = device!.makeBuffer(bytes: verticesArray!, length: dataSize, options: [])
        uniformBuffer = device!.makeBuffer(length: MemoryLayout<matrix_float4x4>.size, options: [])
        
        let library = device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "color_vertex_func")
        let frag_func = library.makeFunction(name: "color_fragment_func")
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        rpld.fragmentFunction = frag_func
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        rpld.depthAttachmentPixelFormat = .depth32Float
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
    
    func draw(commandEncoder:MTLRenderCommandEncoder)
    {
        commandEncoder.setRenderPipelineState(self.rps!)
        commandEncoder.setDepthStencilState(self.depthStencilState)
        
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        
        self.localMVPMatrix = matrix_multiply(self.projectionMatrix, self.modelMatrix)
        
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: localMVPMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
        
        if let samplerState = samplerState {
            commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        }
        let vertexCount = verticesArray!.count
        
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
    }
}

