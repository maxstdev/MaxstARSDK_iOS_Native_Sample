//
//  BackgroundCameraQuad.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2018. 1. 10..
//  Copyright © 2018년 Maxst. All rights reserved.
//

import UIKit
import MaxstARSDKFramework

class BackgroundCameraQuad: BaseModel {
    
    var _lumaTexture:CVOpenGLESTexture?
    var _chromaTexture:CVOpenGLESTexture?
    var _videoTextureCache: CVOpenGLESTextureCache?
    
    var glContext:EAGLContext!
    
    let VERTEX_BUF:[Float] = [
        -0.5, 0.5, 0.0,   // top left
        -0.5, -0.5, 0.0,   // bottom left
        0.5, -0.5, 0.0,   // bottom right
        0.5, 0.5, 0.0  // top right
    ]
    
    let INDEX_BUF:[CUnsignedChar] =
    [
        1, 0, 3, 3, 2, 1
    ]
    
    let TEX_COORD_BUF:[Float] =
    [
        0.0, 1.0,
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
    ]
    
     var textureYHandle:GLuint = 0
     var textureUVHandle:GLuint = 0
    
    var pixelBuffer:CVPixelBuffer? = nil
    
    required init(context:EAGLContext) {
        super.init()
        
        self.glContext = context
        
        VertexShader =
            "attribute vec4 a_position;\n" +
            "uniform mat4 u_mvpMatrix;\n" +
            "attribute vec2 a_vertexTexCoord;\n" +
            "varying vec2 v_texCoord;\n" +
            "void main()\n" +
            "{\n" +
            "    gl_Position = u_mvpMatrix  * a_position;\n" +
            "    v_texCoord = a_vertexTexCoord;             \n" +
        "}\n"
        
        FragmentShader =
            "precision mediump float;\n"         +
            "uniform sampler2D SamplerY;\n"                            +
            "uniform sampler2D SamplerUV;\n"                            +
            "varying vec2 v_texCoord;\n"                                 +
            "void main()\n"                                                 +
            "{\n"                                                         +
            "    float y = texture2D(SamplerY, v_texCoord).r;\n"       +
            "    float u = texture2D(SamplerUV, v_texCoord).r;\n"       +
            "    float v = texture2D(SamplerUV, v_texCoord).g;\n"       +
            "    y = 1.1643 * (y - 0.0625);\n"                            +
            "    u = u - 0.5;\n"                                          +
            "    v = v - 0.5;\n"                                          +
            "    float r = y + 1.5958 * v;\n"                             +
            "    float g = y - 0.39173 * u - 0.81290 * v;\n"              +
            "    float b = y + 2.017 * u;\n"                              +
            "    gl_FragColor = vec4(r, g, b, 1.0);\n"                    +
            "}\n";
        
        vertices = VERTEX_BUF
        textureCoords = TEX_COORD_BUF
        indices = INDEX_BUF
        
        vertexCount = vertices!.count
        texCoordCount = textureCoords!.count
        indexCount = indices!.count
        
        if _videoTextureCache == nil {
            let  err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, self.glContext!, nil, &_videoTextureCache)
            if err != noErr {
                NSLog("Error at CVOpenGLESTextureCacheCreate \(err)")
                return
            }
        }
    }
    
    func cleanUpTextures() {
        _lumaTexture = nil
        
        _chromaTexture = nil
        
        CVOpenGLESTextureCacheFlush(_videoTextureCache!, 0)
    }
    
    func draw(image: MasTrackedImage!, projectionMatrix:matrix_float4x4) {
        if program == 0 {
            program = MasShaderUtil.createProgram(VertexShader, fragment: FragmentShader)
            positionHandle = GLuint(glGetAttribLocation(program, "a_position"))
            mvpMatrixHandle = GLuint(glGetUniformLocation(program, "u_mvpMatrix"))
            textureCoordHandle = GLuint(glGetAttribLocation(program, "a_vertexTexCoord"))
            textureYHandle = GLuint(glGetUniformLocation(program, "SamplerY"))
            textureUVHandle = GLuint(glGetUniformLocation(program, "SamplerUV"))
        }
        
        glUseProgram(program)
        
        glVertexAttribPointer(positionHandle, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, VERTEX_BUF)
        glEnableVertexAttribArray(positionHandle)
        
        glVertexAttribPointer(textureCoordHandle, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, TEX_COORD_BUF)
        glEnableVertexAttribArray(textureCoordHandle)
        
        glUniformMatrix4fv(GLint(mvpMatrixHandle), 1, GLboolean(GL_FALSE), matrixToPointer(matrix: projectionMatrix))
        
        if self.pixelBuffer == nil || image.getWidth() == 0 {
            
            let pixelBufferAttributes = [ kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, kCVPixelBufferWidthKey:image.getWidth(), kCVPixelBufferHeightKey:image.getHeight(),
                                          kCVPixelBufferIOSurfacePropertiesKey : [:],
                                          kCVPixelBufferOpenGLESCompatibilityKey:true] as CFDictionary
            let result = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.getWidth()), Int(image.getHeight()), kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, pixelBufferAttributes, &self.pixelBuffer)
            if result != kCVReturnSuccess {
                print("Unable to create cvpixelbuffer \(result)")
            }
        } else {
            let textureWidth = CVPixelBufferGetWidth(self.pixelBuffer!)
            let textureHeight = CVPixelBufferGetHeight(self.pixelBuffer!)
            
            let imageWidth = image.getWidth()
            let imageHeight = image.getHeight()
            if textureWidth != imageWidth || textureHeight != imageHeight {
                pixelBuffer = nil;
            }
        }
  
        if let buffer = pixelBuffer {
            if(image.getData() == nil) {
                return
            }
            CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
            let pointer:UnsafeMutableRawPointer = UnsafeMutableRawPointer.init(mutating: image.getData())
            let yDestPlane:UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(buffer, 0)!
            
            memcpy(yDestPlane, pointer, Int(image.getWidth()*image.getHeight()))
            let offsetPointer = pointer + Int(image.getWidth()*image.getHeight())
            let uvDestPlane:UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(buffer, 1)!
            let uvLength = image.getWidth()*image.getHeight() / 2
            memcpy(uvDestPlane, offsetPointer, Int(uvLength))
            
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
           
            var err: CVReturn = noErr
            let frameWidth = CVPixelBufferGetWidth(buffer)
            let frameHeight = CVPixelBufferGetHeight(buffer)
            
            guard let videoTextureCache = _videoTextureCache else {
                NSLog("No video texture cache")
                return
            }
            
            self.cleanUpTextures()
            
            glActiveTexture(GLenum(GL_TEXTURE0))
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               videoTextureCache,
                                                               buffer,
                                                               nil,
                                                               GLenum(GL_TEXTURE_2D),
                                                               GL_RED_EXT,
                                                               GLsizei(frameWidth),
                                                               GLsizei(frameHeight),
                                                               GLenum(GL_RED_EXT),
                                                               GLenum(GL_UNSIGNED_BYTE),
                                                               0,
                                                               &_lumaTexture)
            if err != 0 {
                NSLog("Error at CVOpenGLESTextureCacheCreateTextureFromImage \(err)")
            }
            
            glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture!), CVOpenGLESTextureGetName(_lumaTexture!))
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE))
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE))
            glUniform1i(GLint(textureYHandle), 0)
            
            // UV-plane.
            glActiveTexture(GLenum(GL_TEXTURE1))
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               videoTextureCache,
                                                               buffer,
                                                               nil,
                                                               GLenum(GL_TEXTURE_2D),
                                                               GL_RG_EXT,
                                                               GLsizei(frameWidth / 2),
                                                               GLsizei(frameHeight / 2),
                                                               GLenum(GL_RG_EXT),
                                                               GLenum(GL_UNSIGNED_BYTE),
                                                               1,
                                                               &_chromaTexture)
            if err != 0 {
                NSLog("Error at CVOpenGLESTextureCacheCreateTextureFromImage \(err)")
            }
            
            glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture!), CVOpenGLESTextureGetName(_chromaTexture!))
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE))
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE))
            glUniform1i(GLint(textureUVHandle), 1)
        }
        
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(indexCount), GLenum(GL_UNSIGNED_BYTE), INDEX_BUF)
        
        glDisableVertexAttribArray(positionHandle)
        glDisableVertexAttribArray(textureCoordHandle)
        glUseProgram(0)
    }
}
