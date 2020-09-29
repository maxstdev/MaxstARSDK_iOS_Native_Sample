//
//  BoundingBox.swift
//  MaxstARSampleSwiftMetal
//
//  Created by Kimseunglee on 28/09/2018.
//  Copyright © 2018 Maxst. All rights reserved.
//


import UIKit
import MetalKit

class BoundingBox : BaseModel {
    var vertexBuffer: MTLBuffer?
    var colorBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    var samplerState:MTLSamplerState!
    
    static var center_height:Float = -0.2;
    
    var vertices_data:[Float] = [
        0.2 , 0.5 ,    0.5 ,        // V0
        0.5 , 0.2 ,    0.5 ,        // V1
        0.5 , -0.2 , 0.5 ,        // V2
        0.2 , -0.5 , 0.5 ,     // V3
        -0.2 , -0.5 , 0.5 ,    // V4
        -0.5 , -0.2 , 0.5 ,    // V5
        -0.5 , 0.2 , 0.5 ,        // V6
        -0.2 , 0.5 , 0.5 ,        // V7
        
        0.2 , 0.5 ,    center_height,      // V8
        0.5 , 0.2 ,    center_height,    // V9
        0.5 , -0.2 , center_height,        // V10
        0.2 , -0.5 , center_height,        // V11
        -0.2 , -0.5 , center_height,        // V12
        -0.5 , -0.2 , center_height,         // V13
        -0.5 , 0.2 , center_height,        // V14
        -0.2 , 0.5 , center_height,        // V15
        
        0.1 , 0.25 , -0.5 ,        // V16
        0.25 , 0.1 , -0.5 ,        // V17
        0.25 , -0.1 , -0.5 ,        // V18
        0.1 , -0.25 , -0.5 ,        // V19
        -0.1 , -0.25 , -0.5 ,    // V20
        -0.25 , -0.1 , -0.5 ,    // V21
        -0.25 , 0.1 , -0.5 ,        // V22
        -0.1 , 0.25 , -0.5 ,        // V23
    ]
    
    var indices_line:[UInt16] = [
    0,1,
    1,2,
    2,3,
    3,4,
    4,5,
    5,6,
    6,7,
    7,0,
    
    8,9,
    9,10,
    10,11,
    11,12,
    12,13,
    13,14,
    14,15,
    15,8,
    
    16,17,
    17,18,
    18,19,
    19,20,
    20,21,
    21,22,
    22,23,
    23,16,
    
    8,0,
    9,1,
    10,2,
    11,3,
    12,4,
    13,5,
    14,6,
    15,7,
    
    8,16,
    9,17,
    10,18,
    11,19,
    12,20,
    13,21,
    14,22,
    15,23,
    ]
    var indices_mesh:[UInt16] = [
        0, 1, 8,    // 0
        1, 9, 8,
        1, 2, 9,    // 1
        2, 10, 9,
        2, 3, 10,    // 2
        3, 11, 10,
        3, 4, 11,    // 3
        4, 12, 11,
        4, 5, 12,    // 4
        5, 13, 12,
        5, 6, 13,    // 5
        6, 14, 13,
        6, 7, 14,    // 6
        7, 15, 14,
        7, 0, 15,    // 7
        0, 8, 15,
        
        8, 9, 16,    // 8
        9, 17, 16,
        9, 10, 17,    // 9
        10, 18, 17,
        10, 11, 18,    // 10
        11, 19, 18,
        11, 12, 19,    // 11
        12, 20, 19,
        12, 13, 20,    // 12
        13, 21, 20,
        13, 14, 21,    // 13
        14, 22, 21,
        14, 15, 22,    // 14
        15, 23, 22,
        15, 8, 23,    // 15
        8, 16, 23,
        
        18, 19, 20,    // 16
        18, 20, 21,
        18, 21, 22,
        18, 22, 23,
        18, 23, 16,
        18, 16, 17,
    ]
    
    var color_data:[Float] = [
        1.0  , 1.0  , 0.0  , 0.5  ,
        1.0  , 1.0  , 0.0  , 0.5  ,
        1.0  , 1.0  , 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
        1.0, 1.0, 0.0, 0.5,
    ]
    
    private var sliceX:Int = 0
    private var sliceY:Int = 0
    private var sliceZ:Int = 0
    
    var faces:Array<Int> = Array<Int>()
    private var FACE_INDEX_BUF:Array<UInt16>? = nil
    var faceVertexBuffer: MTLBuffer?
    var faceIndexBuffer: MTLBuffer?
    var faceColorBuffer: MTLBuffer?
    
    
    
    var rpld:MTLRenderPipelineDescriptor?
    
    required init(device:MTLDevice!) {
        super.init()
        FACE_INDEX_BUF = [UInt16].init(repeating: 0, count: self.indices_mesh.count)
        self.device = device
        setup()
    }
    
    func setup() {
        self.vertexBuffer = self.device!.makeBuffer(bytes: vertices_data, length: vertices_data.count * MemoryLayout<Float>.size, options: [])
        self.indexBuffer = self.device!.makeBuffer(bytes: indices_line, length: indices_line.count * MemoryLayout<UInt16>.size, options: [])
        self.colorBuffer = self.device!.makeBuffer(bytes: color_data, length: color_data.count * MemoryLayout<Float>.size, options: [])
        self.uniformBuffer = self.device!.makeBuffer(length: MemoryLayout<matrix_float4x4>.size, options: [])
        
        self.faceIndexBuffer = self.device!.makeBuffer(length: MemoryLayout<UInt16>.size*indices_mesh.count, options: [])

        let library = device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "bounding_box_vertex_func")
        let frag_func = library.makeFunction(name: "bounding_box_fragment_func")
        rpld = MTLRenderPipelineDescriptor()
        rpld!.vertexFunction = vertex_func
        rpld!.fragmentFunction = frag_func
        rpld!.colorAttachments[0].pixelFormat = .bgra8Unorm
        rpld!.colorAttachments[0].isBlendingEnabled = false
        rpld!.colorAttachments[0].alphaBlendOperation = .add
        rpld!.colorAttachments[0].rgbBlendOperation = .add
        
        rpld!.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        rpld!.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        
        rpld!.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        rpld!.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        rpld!.depthAttachmentPixelFormat = .depth32Float
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        depthStencilState = device!.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        
        do {
            try rps = device!.makeRenderPipelineState(descriptor: rpld!)
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
    
    func setSlice(x:Int, y:Int, z:Int) {
        sliceX = x
        sliceY = y
        sliceZ = z
    }
    
    func clearFace() {
        faces.removeAll()
    }
    
    func addFace(face:Int) {
        faces.append(face)
    }
    
    func draw(commandEncoder:MTLRenderCommandEncoder) {
  
        do {
            rpld!.colorAttachments[0].isBlendingEnabled = false
            try rps = device!.makeRenderPipelineState(descriptor: rpld!)
        } catch let error {
            NSLog("fail")
            print("\(error)")
        }
        commandEncoder.setRenderPipelineState(self.rps!)
        commandEncoder.setDepthStencilState(depthStencilState)
        
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(colorBuffer, offset: 0, index: 1)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 2)
        
        self.localMVPMatrix = matrix_multiply(self.projectionMatrix, self.modelMatrix)
        
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: localMVPMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
        
        if let samplerState = samplerState {
            commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        }
        
        commandEncoder.drawIndexedPrimitives(type: .line, indexCount: self.indexBuffer!.length / MemoryLayout<UInt16>.size, indexType: MTLIndexType.uint16, indexBuffer: self.indexBuffer!, indexBufferOffset: 0)
        
        let faceCount = faces.count;
        var iindex:Int = 0
        
        for i in 0..<faceCount {
            let face = faces[i]
            
            if(face < 16) {
                FACE_INDEX_BUF![iindex] = indices_mesh[face*2*3+0]
                iindex += 1
                FACE_INDEX_BUF![iindex] = indices_mesh[face*2*3+1]
                iindex += 1
                FACE_INDEX_BUF![iindex] = indices_mesh[face*2*3+2]
                iindex += 1
                FACE_INDEX_BUF![iindex] = indices_mesh[face*2*3+3]
                iindex += 1
                FACE_INDEX_BUF![iindex] = indices_mesh[face*2*3+4]
                iindex += 1
                FACE_INDEX_BUF![iindex] = indices_mesh[face*2*3+5]
                iindex += 1
            } else {
                for j in 32..<38 {
                    FACE_INDEX_BUF![iindex] = indices_mesh[j*3+0]
                    iindex += 1
                    FACE_INDEX_BUF![iindex] = indices_mesh[j*3+1]
                    iindex += 1
                    FACE_INDEX_BUF![iindex] = indices_mesh[j*3+2]
                    iindex += 1
                }
            }
        }

        if faceCount > 0 {
            self.faceIndexBuffer = self.device!.makeBuffer(bytes: self.FACE_INDEX_BUF!, length: iindex * MemoryLayout<UInt16>.size, options: [])
            do {
                rpld!.colorAttachments[0].isBlendingEnabled = true
                try rps = device!.makeRenderPipelineState(descriptor: rpld!)
            } catch let error {
                NSLog("fail")
                print("\(error)")
            }
            
            commandEncoder.setRenderPipelineState(self.rps!)
            self.localMVPMatrix = matrix_multiply(self.projectionMatrix, self.modelMatrix)
            
            let bufferPointer = uniformBuffer.contents()
            var uniforms = Uniforms(modelViewProjectionMatrix: localMVPMatrix)
            memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
            
            commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            commandEncoder.setVertexBuffer(colorBuffer, offset: 0, index: 1)
            commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 2)
            
            if let samplerState = samplerState {
                commandEncoder.setFragmentSamplerState(samplerState, index: 0)
            }
            commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: self.faceIndexBuffer!.length / MemoryLayout<UInt16>.size, indexType: MTLIndexType.uint16, indexBuffer: self.faceIndexBuffer!, indexBufferOffset: 0)
        }
        
    }
}

