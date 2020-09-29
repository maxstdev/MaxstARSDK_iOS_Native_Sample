//
//  ColorCube.swift
//  MaxstARSampleSwift
//
//  Created by Kimseunglee on 2017. 12. 14..
//  Copyright © 2017년 Maxst. All rights reserved.
//

import UIKit
import MaxstARSDKFramework

class ColorCube: BaseModel {
    let VERTEX_BUF:[Float] =
    [    //Vertices according to faces
    -0.5, -0.5, -0.5, // 0
    0.5, -0.5, -0.5, // 1
    0.5, 0.5, -0.5, // 2
    -0.5, 0.5, -0.5, // 3
    -0.5, -0.5, 0.5, // 4
    0.5, -0.5, 0.5, // 5
    0.5, 0.5, 0.5, // 6
    -0.5, 0.5, 0.5, // 7
    ]
    
    let INDEX_BUF:[CUnsignedChar] =
    [
    0, 2, 3, 2, 0, 1, // back face
    0, 7, 4, 7, 0, 3, // left face
    1, 6, 2, 6, 1, 5, // right face
    0, 5, 1, 5, 0, 4, // bottom face
    3, 6, 7, 6, 3, 2, // up face
    4, 6, 5, 6, 4, 7, // front face
    ]
    
    let COLOR_BUF:[Float] =
    [
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    0.0, 0.0, 0.0, 1.0,
    0.0, 0.0, 0.0, 1.0,
    0.0, 0.0, 0.0, 1.0,
    0.0, 0.0, 0.0, 1.0,
    ]
    
    override init() {
        super.init()
        
        VertexShader =
        "attribute vec4 a_position;\n" +
        "attribute vec4 a_color;\n" +
        "uniform mat4 u_mvpMatrix;\n" +
        "varying vec4 v_color;\n" +
        "void main()\n" +
        "{\n" +
        "    gl_Position = u_mvpMatrix  * a_position;\n" +
        "    v_color = a_color;\n" +
        "}\n"
        
        FragmentShader =
        "precision mediump float;\n" +
        "varying vec4 v_color;\n" +
        "void main()\n" +
        "{\n" +
        "    gl_FragColor = v_color;\n" +
        "}\n"
        
        vertices = VERTEX_BUF
        colors = COLOR_BUF
        indices = INDEX_BUF
        
        vertexCount = vertices!.count
        indexCount = indices!.count
    }
    
    override func draw() {
        if program == 0
        {
            program = MasShaderUtil.createProgram(VertexShader, fragment: FragmentShader)
            positionHandle = GLuint(glGetAttribLocation(program, "a_position"));
            colorHandle = GLuint(glGetAttribLocation(program, "a_color"));
            mvpMatrixHandle = GLuint(glGetUniformLocation(program, "u_mvpMatrix"));
        }
        
        glUseProgram(program);
        
        glVertexAttribPointer(positionHandle, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, vertices);
        glEnableVertexAttribArray(positionHandle);
        
        glVertexAttribPointer(colorHandle, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, colors);
        glEnableVertexAttribArray(colorHandle);
        
        self.localMVPMatrix = matrix_multiply(self.projectionMatrix, self.modelMatrix);
        
        glUniformMatrix4fv(GLint(mvpMatrixHandle), 1, GLboolean(GL_FALSE), matrixToPointer(matrix: self.localMVPMatrix));
        
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(indexCount), GLenum(GL_UNSIGNED_BYTE), indices);
        
        glDisableVertexAttribArray(positionHandle);
        glDisableVertexAttribArray(colorHandle);
        glUseProgram(0);
    }
}
