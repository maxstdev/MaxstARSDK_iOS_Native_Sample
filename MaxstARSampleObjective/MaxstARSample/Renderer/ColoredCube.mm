//
//  MColoredCube.m
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 12. 10..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import "ColoredCube.h"

@interface ColoredCube()
{
    NSString *_vertexString;
    NSString *_fragmentString;
}
@end

@implementation ColoredCube
- (instancetype)init {
    self = [super init];
    if (self) {
        float VERTEX_BUF[] =
        {    //Vertices according to faces
            -0.5f, -0.5f, -0.5f, // 0
            0.5f, -0.5f, -0.5f, // 1
            0.5f, 0.5f, -0.5f, // 2
            -0.5f, 0.5f, -0.5f, // 3
            -0.5f, -0.5f, 0.5f, // 4
            0.5f, -0.5f, 0.5f, // 5
            0.5f, 0.5f, 0.5f, // 6
            -0.5f, 0.5f, 0.5f, // 7
        };
        
        unsigned char INDEX_BUF[] =
        {
            0, 2, 3, 2, 0, 1, // back face
            0, 7, 4, 7, 0, 3, // left face
            1, 6, 2, 6, 1, 5, // right face
            0, 5, 1, 5, 0, 4, // bottom face
            3, 6, 7, 6, 3, 2, // up face
            4, 6, 5, 6, 4, 7, // front face
        };
        
        float COLOR_BUF[] =
        {
            1.0f, 1.0f, 1.0f, 1.0f,
            1.0f, 1.0f, 1.0f, 1.0f,
            1.0f, 1.0f, 1.0f, 1.0f,
            1.0f, 1.0f, 1.0f, 1.0f,
            0.0f, 0.0f, 0.0f, 1.0f,
            0.0f, 0.0f, 0.0f, 1.0f,
            0.0f, 0.0f, 0.0f, 1.0f,
            0.0f, 0.0f, 0.0f, 1.0f,
        };
        
        NSString * VERTEX_SHADER_SRC =
        @"attribute vec4 a_position;\n"                                \
        @"attribute vec4 a_color;\n"                                    \
        @"uniform mat4 u_mvpMatrix;\n"                                \
        @"varying vec4 v_color;\n"                    \
        @"void main()\n"                                                    \
        @"{\n"                                                            \
        @"    gl_Position = u_mvpMatrix  * a_position;\n"                    \
        @"    v_color = a_color;\n"                                        \
        @"}\n";
        
        NSString * FRAGMENT_SHADER_SRC =
        @"precision mediump float;\n"
        @"varying vec4 v_color;\n"                    \
        @"void main()\n"                                    \
        @"{\n"                                            \
        @"    gl_FragColor = v_color;\n"                    \
        @"}\n";
        
        _vertexString = VERTEX_SHADER_SRC;
        _fragmentString = FRAGMENT_SHADER_SRC;
        
        vertices = new float[sizeof(VERTEX_BUF)];
        colors = new float[sizeof(COLOR_BUF)];
        indices = new unsigned char[sizeof(INDEX_BUF)];
        
        memcpy(vertices, VERTEX_BUF, sizeof(VERTEX_BUF));
        memcpy(colors, COLOR_BUF, sizeof(COLOR_BUF));
        memcpy(indices, INDEX_BUF, sizeof(INDEX_BUF));
        
        vertexCount = sizeof(VERTEX_BUF) / sizeof(float);
        indexCount = sizeof(INDEX_BUF) / sizeof(unsigned char);
    }
    return self;
}

- (void) draw {
    if (program == 0)
    {
        program = [MasShaderUtil createProgram:_vertexString fragment:_fragmentString];
        positionHandle = glGetAttribLocation(program, "a_position");
        colorHandle = glGetAttribLocation(program, "a_color");
        mvpMatrixHandle = glGetUniformLocation(program, "u_mvpMatrix");
    }
    
    glUseProgram(program);
    
    glVertexAttribPointer(positionHandle, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(positionHandle);
    
    glVertexAttribPointer(colorHandle, 4, GL_FLOAT, GL_FALSE, 0, colors);
    glEnableVertexAttribArray(colorHandle);
    
    _localMVPMatrix = matrix_multiply(_projectionMatrix, _modelMatrix);
    
    glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const float *)&_localMVPMatrix);
    
    glDrawElements(GL_TRIANGLES, indexCount, GL_UNSIGNED_BYTE, indices);
    
    glDisableVertexAttribArray(positionHandle);
    glDisableVertexAttribArray(colorHandle);
    glUseProgram(0);
}
@end
