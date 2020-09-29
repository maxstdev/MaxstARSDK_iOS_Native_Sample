//
//  BackgroundCameraQuad.swift
//  MaxstARSampleSwiftMetal
//
//  Created by Kimseunglee on 2018. 1. 11..
//  Copyright © 2018년 Maxst. All rights reserved.
//

import UIKit
import MetalKit
import Metal
import MaxstARSDKFramework

class BackgroundCameraQuad {
    var rps: MTLRenderPipelineState?
    var vertexData:[Vertex]?
    var vertexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    var texture: MTLTexture?
    var samplerState:MTLSamplerState!
    
    var device: MTLDevice?
    
    var _lumaTexture:MTLTexture?
    var _chromaTexture:MTLTexture?
    var _videoTextureCache:CVMetalTextureCache?
    var _colorConversionBuffer:MTLBuffer!
    
    var textureY:CVMetalTexture?
    var textureUV:CVMetalTexture?
    
    var pixelBuffer:CVPixelBuffer? = nil
    
    var projectionMatix:matrix_float4x4!  = matrix_identity_float4x4
    var viewMatrix:matrix_float4x4! = matrix_identity_float4x4
    var modelMatrix:matrix_float4x4! = matrix_identity_float4x4
    var localMVPMatrix:matrix_float4x4! = matrix_identity_float4x4
    
    
    var positionX:Float = 0.0
    var positionY:Float = 0.0
    var positionZ:Float = 0.0
    
    var rotationX:Float = 0.0
    var rotationY:Float = 0.0
    var rotationZ:Float = 0.0
    
    var scaleX:Float    = 1.0
    var scaleY:Float    = 1.0
    var scaleZ:Float    = 1.0
    
    //Front
    let A = Vertex(x: -0.5, y:   0.5, z:   0.0, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 0, t: 1)
    let B = Vertex(x: -0.5, y:  -0.5, z:   0.0, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 0, t: 0)
    let C = Vertex(x:  0.5, y:  -0.5, z:   0.0, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 1, t: 0)
    let D = Vertex(x:  0.5, y:   0.5, z:   0.0, r:  1.0, g:  1.0, b:  1.0, a:  1.0, s: 1, t: 1)
    
    // 2
    var verticesArray:Array<Vertex>?
    
    required init(device:MTLDevice!) {
        
        self.device = device
        
        verticesArray = [
            A,B,C,C,D,A,
        ]
        setup()
        
        if _videoTextureCache == nil {
            
            let  err = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self.device!, nil, &_videoTextureCache)
            if err != noErr {
                NSLog("Error at CVOpenGLESTextureCacheCreate \(err)")
                return
            }
        }
    }
    
    func cleanUpTextures() {
        _lumaTexture = nil
        
        _chromaTexture = nil
        
        CVMetalTextureCacheFlush(_videoTextureCache!, 0)
    }
    
    func setup() {
        let dataSize = verticesArray!.count * MemoryLayout<Vertex>.size
        vertexBuffer = device!.makeBuffer(bytes: verticesArray!, length: dataSize, options: [])
        uniformBuffer = device!.makeBuffer(length: MemoryLayout<matrix_float4x4>.size, options: [])
        
        let conversion:ColorConversion = ColorConversion(matrix: .init(simd_float3(1.164,1.164,1.164),simd_float3(0.000, -0.392, 2.017),simd_float3(1.596, -0.813, 0.000)), offset: vector_float3( -(16.0/255.0), -0.5, -0.5))
        
        let conversions:Array<ColorConversion> = [conversion]
        
        self._colorConversionBuffer = device!.makeBuffer(bytes: conversions, length: MemoryLayout<ColorConversion>.size, options: MTLResourceOptions.optionCPUCacheModeWriteCombined)
        
        let library = device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "camerabackground_vertex_func")
        let frag_func = library.makeFunction(name: "camerabackground_fragment_func")
        
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
        
    }
    
    func draw(commandEncoder:MTLRenderCommandEncoder, image: CVPixelBuffer!)
    {
        self.pixelBuffer = image
        
        if let buffer:CVPixelBuffer = pixelBuffer {
            guard let videoTextureCache = _videoTextureCache else {
                NSLog("No video texture cache")
                return
            }
            
            self.cleanUpTextures()
            
            _lumaTexture = createTexture(fromPixelBuffer: buffer, pixelFormat:.r8Unorm, planeIndex:0, textureCache:videoTextureCache)
            _chromaTexture = createTexture(fromPixelBuffer: buffer, pixelFormat:.rg8Unorm, planeIndex:1, textureCache:videoTextureCache)
            
        }
        
        moveModel();
        commandEncoder.setRenderPipelineState(self.rps!)
        
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        
        commandEncoder.setFragmentTexture(_lumaTexture, index: 0)
        commandEncoder.setFragmentTexture(_chromaTexture, index: 1)
        commandEncoder.setFragmentBuffer(_colorConversionBuffer, offset: 0, index: 0)
        
        let vertexCount = verticesArray!.count
        
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
    }
    
    func draw(commandEncoder:MTLRenderCommandEncoder, image: MasTrackedImage!)
    {
        if self.pixelBuffer == nil {
            let pixelBufferAttributes = [ kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, kCVPixelBufferWidthKey:image.getWidth(), kCVPixelBufferHeightKey:image.getHeight(),
                kCVPixelBufferIOSurfacePropertiesKey : [:],
                kCVPixelBufferMetalCompatibilityKey:true] as CFDictionary
            let result = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.getWidth()), Int(image.getHeight()), kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, pixelBufferAttributes, &self.pixelBuffer)
            
            if result != kCVReturnSuccess {
                print("Unable to create cvpixelbuffer \(result)")
            }
        }  else {
            let textureWidth = CVPixelBufferGetWidth(self.pixelBuffer!)
            let textureHeight = CVPixelBufferGetHeight(self.pixelBuffer!)
            
            let imageWidth = image.getWidth()
            let imageHeight = image.getHeight()
            if textureWidth != imageWidth || textureHeight != imageHeight {
                pixelBuffer = nil;
            }
        }
        
        if let buffer:CVPixelBuffer = pixelBuffer {
            
            if(image.getData() == nil) {
                return
            }
            
            CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            let pointer:UnsafeMutableRawPointer = UnsafeMutableRawPointer.init(mutating: image.getData())
            let yDestPlane:UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(buffer, 0)!
            let uvDestPlane:UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(buffer, 1)!
            let imageWidth = image.getWidth()
            let imageHeight = image.getHeight()
            
            let padding:Int = Int(imageWidth % 64)
            if(padding != 0) {
                var offsetYPointer = yDestPlane
                var offsetPointer = pointer
                for _ in 0...(imageHeight-1) {
                    memcpy(offsetYPointer, offsetPointer, Int(image.getWidth()))
                    offsetYPointer = offsetYPointer + Int(image.getWidth())
                    offsetYPointer = offsetYPointer + padding
                    offsetPointer = offsetPointer + Int(image.getWidth())
                }
                
                var offsetUVPointer = uvDestPlane
                for _ in 0...(imageHeight-1)/2 {
                    memcpy(offsetUVPointer, offsetPointer, Int(image.getWidth()))
                    offsetUVPointer = offsetUVPointer + Int(image.getWidth())
                    offsetUVPointer = offsetUVPointer + padding
                    offsetPointer = offsetPointer + Int(image.getWidth())
                }
            } else {
                memcpy(yDestPlane, pointer, Int(image.getWidth()*image.getHeight()))
                let offsetPointer = pointer + Int(image.getWidth()*image.getHeight())
                
                let uvLength = image.getWidth()*image.getHeight() / 2
                memcpy(uvDestPlane, offsetPointer, Int(uvLength))
            }
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            
            guard let videoTextureCache = _videoTextureCache else {
                NSLog("No video texture cache")
                return
            }
            
            self.cleanUpTextures()
        
            _lumaTexture = createTexture(fromPixelBuffer: buffer, pixelFormat:.r8Unorm, planeIndex:0, textureCache:videoTextureCache)
            _chromaTexture = createTexture(fromPixelBuffer: buffer, pixelFormat:.rg8Unorm, planeIndex:1, textureCache:videoTextureCache)

        }
        
        moveModel();
        commandEncoder.setRenderPipelineState(self.rps!)
        
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)

        commandEncoder.setFragmentTexture(_lumaTexture, index: 0)
        commandEncoder.setFragmentTexture(_chromaTexture, index: 1)
        commandEncoder.setFragmentBuffer(_colorConversionBuffer, offset: 0, index: 0)
        
        let vertexCount = verticesArray!.count
        
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
    }
    
    func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int, textureCache:CVMetalTextureCache) -> MTLTexture? {
        var mtlTexture: MTLTexture? = nil
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        if status == kCVReturnSuccess {
            mtlTexture = CVMetalTextureGetTexture(texture!)
        }
        
        return mtlTexture
    }
    
    private func moveModel() {
        let position:matrix_float4x4 = getTranslationMatrix(vector_float4([positionX, positionY, positionZ, 1.0]))
        var rotation:matrix_float4x4 = getRotationAroundX(rotationX)
        rotation = matrix_multiply(rotation, getRotationAroundY(rotationY))
        rotation = matrix_multiply(rotation, getRotationAroundZ(rotationZ))
        let scale:matrix_float4x4 = getScaleMatrix(scaleX, y: scaleY, z: scaleZ)
        
        self.modelMatrix = matrix_multiply(position, scale)
        self.modelMatrix = matrix_multiply(modelMatrix, rotation)
        self.localMVPMatrix = matrix_multiply(self.projectionMatix, matrix_multiply(self.viewMatrix, self.modelMatrix))
        
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: localMVPMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
    }
    
    func setProjectionMatrix(projectionMatrix:matrix_float4x4)
    {
        self.projectionMatix = projectionMatrix
    }
    
    func setViewMatrix(viewMatrix:matrix_float4x4)
    {
        self.viewMatrix = viewMatrix
    }
    
    func setTranslate(x:Float, y:Float, z:Float)
    {
        self.positionX = self.positionX + x
        self.positionY = self.positionY + y
        self.positionZ = self.positionZ + z
    }
    
    func setPosition(x:Float, y:Float, z:Float)
    {
        self.positionX = x
        self.positionY = y
        self.positionZ = z
    }
    
    func setRotate(x:Float, y:Float, z:Float)
    {
        self.rotationX = self.rotationX + x
        self.rotationY = self.rotationY + y
        self.rotationZ = self.rotationZ + z
    }
    
    func setRotation(x:Float, y:Float, z:Float)
    {
        self.rotationX = x
        self.rotationY = y
        self.rotationZ = z
    }
    
    func setScale(x:Float, y:Float, z:Float)
    {
        self.scaleX = x
        self.scaleY = y
        self.scaleZ = z
    }
}
