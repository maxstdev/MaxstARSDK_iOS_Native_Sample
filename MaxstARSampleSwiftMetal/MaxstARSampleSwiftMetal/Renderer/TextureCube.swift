//
//  CubeRenderer.swift
//  MetalTest
//
//  Created by Kimseunglee on 2017. 9. 26..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import MetalKit
import MaxstARSDKFramework

class TextureCube : BaseModel {
    var positionBuffer: MTLBuffer?
    var textureCoordBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    var texture: MTLTexture!
    var samplerState:MTLSamplerState!
   
    let VERTEX_BUF:[Float] =
        [
            -0.5, -0.5, -0.5,
            0.5, -0.5, -0.5,
            0.5, 0.5, -0.5,
            0.5, 0.5, -0.5,
            -0.5, 0.5, -0.5,
            -0.5, -0.5, -0.5,
            
            -0.5, -0.5, 0.5,
            -0.5, 0.5, 0.5,
            0.5, 0.5, 0.5,
            0.5, 0.5, 0.5,
            0.5, -0.5, 0.5,
            -0.5, -0.5, 0.5,
            
            -0.5, -0.5, -0.5,
            -0.5, -0.5, 0.5,
            0.5, -0.5, 0.5,
            0.5, -0.5, 0.5,
            0.5, -0.5, -0.5,
            -0.5, -0.5, -0.5,
            
            0.5, -0.5, -0.5,
            0.5, -0.5, 0.5,
            0.5,  0.5, 0.5,
            0.5, 0.5, 0.5,
            0.5, 0.5, -0.5,
            0.5, -0.5, -0.5,
            
            0.5, 0.5, -0.5,
            0.5, 0.5, 0.5,
            -0.5, 0.5, 0.5,
            -0.5, 0.5, 0.5,
            -0.5, 0.5, -0.5,
            0.5, 0.5, -0.5,
            
            -0.5, 0.5, -0.5,
            -0.5, 0.5, 0.5,
            -0.5, -0.5, 0.5,
            -0.5, -0.5, 0.5,
            -0.5, -0.5, -0.5,
            -0.5, 0.5, -0.5,
            ]
    
    let TEX_COORD_BUF:[Float] =
        [
            0.167, 0.100,
            0.833, 0.100,
            0.833, 0.500,
            0.833, 0.500,
            0.167, 0.500,
            0.167, 0.100,
            
            0.167, 0.667,
            0.833, 0.667,
            0.833, 1.000,
            0.833, 1.000,
            0.167, 1.000,
            0.167, 0.667,
            
            0.167, 0.000,
            0.833, 0.000,
            0.833, 0.100,
            0.833, 0.100,
            0.167, 0.100,
            0.167, 0.000,
            
            0.833, 0.100,
            1.000, 0.100,
            1.000, 0.500,
            1.000, 0.500,
            0.833, 0.500,
            0.833, 0.100,
            
            0.167, 0.000,
            0.833, 0.000,
            0.833, 0.100,
            0.833, 0.100,
            0.167, 0.100,
            0.167, 0.000,
            
            0.833, 0.500,
            0.833, 0.100,
            1.000, 0.100,
            1.000, 0.100,
            1.000, 0.500,
            0.833, 0.500,
            ]
    
    required init(device:MTLDevice!) {
        super.init()
        
        self.device = device
        
        setup()
    }
    
    func imageChange(image:UIImage) -> UIImage {
        let imageRef = image.cgImage!
        
        let width = imageRef.width
        let height = imageRef.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB();
    
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
    
        context?.translateBy(x: 0, y: CGFloat(height))
        context!.scaleBy(x: 1, y: -1)
        
        context!.draw(imageRef, in: CGRect.init(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        
        return UIImage.init(cgImage: imageRef)
    }
    
    func setTexture(textureImage:UIImage!) {
        let textureLoader = MTKTextureLoader(device: device!)
        texture = try! textureLoader.newTexture(cgImage: textureImage.cgImage!, options: nil)
    }
    
    func setup() {
        self.positionBuffer = self.device!.makeBuffer(bytes: VERTEX_BUF, length: VERTEX_BUF.count * MemoryLayout<Float>.size, options: [])
        self.textureCoordBuffer = self.device!.makeBuffer(bytes: TEX_COORD_BUF, length: TEX_COORD_BUF.count * MemoryLayout<Float>.size, options: [])
        uniformBuffer = device!.makeBuffer(length: MemoryLayout<matrix_float4x4>.size, options: [])
        
        let library = device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "new_textured_vertex_func")
        let frag_func = library.makeFunction(name: "new_textured_fragment_func")
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
        
        commandEncoder.setVertexBuffer(positionBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(textureCoordBuffer, offset: 0, index: 1)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 2)
        commandEncoder.setFragmentTexture(texture, index: 0)
        
        self.localMVPMatrix = matrix_multiply(self.projectionMatrix, self.modelMatrix)
        
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: localMVPMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
        
        if let samplerState = samplerState {
            commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        }
        
        let vertexCount = Int(VERTEX_BUF.count)/3
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
    }
}
