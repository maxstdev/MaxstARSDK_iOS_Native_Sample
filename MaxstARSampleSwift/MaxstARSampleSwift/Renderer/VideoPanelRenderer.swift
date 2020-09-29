//
//  VideoPanelRenerer.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 14..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import MaxstARSDKFramework

class VideoPanelRenderer: BaseModel {
    var width = 0
    var height = 0
    
    let VERTEX_BUF:[Float] =
    [
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
    
    override init() {
        super.init()
        
        VertexShader =
            "attribute vec4 a_position;\n" +
            "attribute vec2 a_vertexTexCoord;\n" +
            "uniform mat4 u_mvpMatrix;\n" +
            "varying vec2 v_texCoord;\n" +
            "void main()\n" +
            "{\n" +
            "    gl_Position = u_mvpMatrix  * a_position;\n" +
            "    v_texCoord = a_vertexTexCoord;             \n" +
            "}\n"
        
        FragmentShader =
            "precision mediump float;\n" +
            "uniform sampler2D u_texture;\n" +
            "varying vec2 v_texCoord;\n" +
            "void main()\n" +
            "{\n" +
            "    gl_FragColor = texture2D(u_texture, v_texCoord);\n" +
            "}\n"
        
        vertices = VERTEX_BUF
        textureCoords = TEX_COORD_BUF
        indices = INDEX_BUF
        
        vertexCount = vertices!.count
        indexCount = indices!.count
    }
    
    func setVideoSize(width:Int, height:Int) {
        self.width = width
        self.height = height
    }
    
    func draw(videoTextureId:GLuint) {
        if self.width == 0 || self.height == 0 || videoTextureId == 0
        {
            return;
        }
        
        if (program == 0)
        {
            program = MasShaderUtil.createProgram(VertexShader, fragment: FragmentShader)
            
            positionHandle = GLuint(glGetAttribLocation(program, "a_position"));
            textureCoordHandle = GLuint(glGetAttribLocation(program, "a_vertexTexCoord"));
            mvpMatrixHandle = GLuint(glGetUniformLocation(program, "u_mvpMatrix"));
            textureHandle = GLuint(glGetUniformLocation(program, "u_texture"));
        }
        
        glUseProgram(program);
        
        glVertexAttribPointer(positionHandle, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, vertices);
        glEnableVertexAttribArray(positionHandle);
        
        glVertexAttribPointer(textureCoordHandle, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, textureCoords);
        glEnableVertexAttribArray(textureCoordHandle);
        
        self.localMVPMatrix = matrix_multiply(self.projectionMatrix, self.modelMatrix);
        glUniformMatrix4fv(GLint(mvpMatrixHandle), 1, GLboolean(GL_FALSE), matrixToPointer(matrix: self.localMVPMatrix));
        
        glActiveTexture(GLenum(GL_TEXTURE0));
        glUniform1i(GLint(textureHandle), 0);
        glBindTexture(GLenum(GL_TEXTURE_2D), videoTextureId);
        
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(indexCount), GLenum(GL_UNSIGNED_BYTE), indices);
        
        glDisableVertexAttribArray(positionHandle);
        glDisableVertexAttribArray(textureCoordHandle);
        
        glUseProgram(0)
    }
}
