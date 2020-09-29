//
//  TextureCube.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 13..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import MaxstARSDKFramework

class TextureCube: BaseModel {
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
    
    var _image:UIImage? = nil
    
    override init() {
        super.init()
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
            "precision mediump float;\n" +
                "uniform sampler2D u_texture_1;\n" +
                "varying vec2 v_texCoord;\n" +
                "void main()\n" +
                "{\n" +
                "    gl_FragColor = texture2D(u_texture_1, v_texCoord.xy);\n" +
        "}\n"
        
        vertices = VERTEX_BUF
        textureCoords = TEX_COORD_BUF
        
        vertexCount = vertices!.count
        texCoordCount = textureCoords!.count
    }
    
    func setTexture(image:UIImage) {
        _image = image
    }
    
    override func draw() {
        if program == 0 {
            program = MasShaderUtil.createProgram(VertexShader, fragment: FragmentShader)
            positionHandle = GLuint(glGetAttribLocation(program, "a_position"))
            mvpMatrixHandle = GLuint(glGetUniformLocation(program, "u_mvpMatrix"))
            textureCoordHandle = GLuint(glGetAttribLocation(program, "a_vertexTexCoord"))
            textureHandle = GLuint(glGetUniformLocation(program, "u_texture_1"))
            
            glGenTextures(1, &textureId)
            glBindTexture(GLenum(GL_TEXTURE_2D), textureId)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR);
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
            
            let imageData:UnsafeMutableRawPointer = ByteArrary(image: _image!)
            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(GLenum(GL_TEXTURE_2D), textureId)
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(_image!.size.width), GLsizei(_image!.size.height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), imageData)
            
            free(imageData)
        }
        
        glUseProgram(program);
        
        glVertexAttribPointer(positionHandle, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, vertices);
        glEnableVertexAttribArray(positionHandle);
        
        glVertexAttribPointer(textureCoordHandle, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, textureCoords);
        glEnableVertexAttribArray(textureCoordHandle);
        
        self.localMVPMatrix = matrix_multiply(self.projectionMatrix, self.modelMatrix);
        
        glUniformMatrix4fv(GLint(mvpMatrixHandle), 1, GLboolean(GL_FALSE), matrixToPointer(matrix: self.localMVPMatrix));
        
        if(textureId != 0) {
            glActiveTexture(GLenum(GL_TEXTURE0));
            glUniform1i(GLint(textureHandle), 0);
            glBindTexture(GLenum(GL_TEXTURE_2D), textureId);
        }
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6 * 6);
        
        glDisableVertexAttribArray(positionHandle);
        glDisableVertexAttribArray(textureCoordHandle);
        glUseProgram(0);
    }
    
    func ByteArrary(image:UIImage) -> UnsafeMutableRawPointer {
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let imageRef:CGImage = image.cgImage!
        let imageData: UnsafeMutableRawPointer = malloc(Int(image.size.width * image.size.height * 4))
        let ctx = CGContext(data: imageData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: Int(image.size.width * 4), space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

        ctx?.setBlendMode(CGBlendMode.copy)
        ctx?.draw(imageRef, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))

        return imageData
    }
}
