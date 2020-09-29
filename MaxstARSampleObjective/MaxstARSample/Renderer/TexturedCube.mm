//
//  MTexturedCube.m
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 12. 10..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import "TexturedCube.h"
#import "UIImage+Converter.h"

@interface TexturedCube()
{
    UIImage *_image;
    NSString *_vertexString;
    NSString *_fragmentString;
}
@end

@implementation TexturedCube


- (instancetype)init {
    self = [super init];
    if (self) {
//        float VERTEX_BUF[] =
//        {    //Vertices according to faces
//            // 1. Up face
//
//            -0.5f, -0.5f, -0.5f,
//            0.5f, -0.5f, -0.5f,
//            0.5f, 0.5f, -0.5f,
//            0.5f, 0.5f, -0.5f,
//            -0.5f, 0.5f, -0.5f,
//            -0.5f, -0.5f, -0.5f,
//
//            // 2. Bottom face
//            -0.5f, -0.5f, 0.5f,
//            -0.5f, 0.5f, 0.5f,
//            0.5f, 0.5f, 0.5f,
//            0.5f, 0.5f, 0.5f,
//            0.5f, -0.5f, 0.5f,
//            -0.5f, -0.5f, 0.5f,
//
//            // 3. Front face
//            -0.5f, -0.5f, -0.5f,
//            -0.5f, -0.5f, 0.5f,
//            0.5f, -0.5f, 0.5f,
//            0.5f, -0.5f, 0.5f,
//            0.5f, -0.5f, -0.5f,
//            -0.5f, -0.5f, -0.5f,
//
//            // 4. Right face
//            0.5f, -0.5f, -0.5f,
//            0.5f, -0.5f, 0.5f,
//            0.5f,  0.5f, 0.5f,
//            0.5f, 0.5f, 0.5f,
//            0.5f, 0.5f, -0.5f,
//            0.5f, -0.5f, -0.5f,
//
//            // 5. Back face
//            0.5f, 0.5f, -0.5f,
//            0.5f, 0.5f, 0.5f,
//            -0.5f, 0.5f, 0.5f,
//            -0.5f, 0.5f, 0.5f,
//            -0.5f, 0.5f, -0.5f,
//            0.5f, 0.5f, -0.5f,
//
//            // 6. Left face
//            -0.5f, 0.5f, -0.5f,
//            -0.5f, 0.5f, 0.5f,
//            -0.5f, -0.5f, 0.5f,
//            -0.5f, -0.5f, 0.5f,
//            -0.5f, -0.5f, -0.5f,
//            -0.5f, 0.5f, -0.5f,
//        };
        
        float VERTEX_BUF[] =
        {    //Vertices according to faces
            // 1. Up face
            
            -0.5f, -0.5f, -0.5f,
            0.5f, -0.5f, -0.5f,
            0.5f, 0.5f, -0.5f,
            -0.5f, 0.5f, -0.5f,
            
            // 2. Bottom face
            -0.5f, -0.5f, 0.5f,
            -0.5f, 0.5f, 0.5f,
            0.5f, 0.5f, 0.5f,
            0.5f, -0.5f, 0.5f,
            
            // 3. Back face
            -0.5f, -0.5f, -0.5f,
            -0.5f, -0.5f, 0.5f,
            0.5f, -0.5f, 0.5f,
            0.5f, -0.5f, -0.5f,
            
            // 4. Right face
            0.5f, -0.5f, -0.5f,
            0.5f, -0.5f, 0.5f,
            0.5f,  0.5f, 0.5f,
            0.5f, 0.5f, -0.5f,
            
            // 5. Front face
            0.5f, 0.5f, -0.5f,
            0.5f, 0.5f, 0.5f,
            -0.5f, 0.5f, 0.5f,
            -0.5f, 0.5f, -0.5f,
            
            // 6. Left face
            -0.5f, 0.5f, -0.5f,
            -0.5f, 0.5f, 0.5f,
            -0.5f, -0.5f, 0.5f,
            -0.5f, -0.5f, -0.5f,
        };
        
        unsigned char INDEX_BUF[] =
        {
            1,  0, 3, 3, 2, 1,
            4,  7, 6, 6, 5, 4,
            8, 11,10,10, 9, 8,
            13,12,15,15,14,13,
            17,16,19,19,18,17,
            21,20,23,23,22,21,
        };
        
        float TEX_COORD_BUF[] =
        {
            0.167f, 0.100f,
            0.833f, 0.100f,
            0.833f, 0.500f,
            0.167f, 0.500f,
            
            0.167f, 0.667f,
            0.833f, 0.667f,
            0.833f, 1.000f,
            0.167f, 1.000f,
            
            0.167f, 0.000f,
            0.833f, 0.000f,
            0.833f, 0.100f,
            0.167f, 0.100f,
            
            0.833f, 0.100f,
            1.000f, 0.100f,
            1.000f, 0.500f,
            0.833f, 0.500f,
            
            0.167f, 0.000f,
            0.833f, 0.000f,
            0.833f, 0.100f,
            0.167f, 0.100f,
            
            0.833f, 0.500f,
            0.833f, 0.100f,
            1.000f, 0.100f,
            1.000f, 0.500f,
        };
        
        NSString *VERTEX_SHADER_SRC =
        @"attribute vec4 a_position;\n"                                \
        @"uniform mat4 u_mvpMatrix;\n"                                \
        @"attribute vec2 a_vertexTexCoord;\n"                    \
        @"varying vec2 v_texCoord;\n"                        \
        @"void main()\n"                                                    \
        @"{\n"                                                            \
        @"    gl_Position = u_mvpMatrix  * a_position;\n"                    \
        @"    v_texCoord = a_vertexTexCoord;             \n"        \
        @"}\n";
        
        NSString *FRAGMENT_SHADER_SRC =
        @"precision mediump float;\n"
        @"uniform sampler2D u_texture_1;\n"                            \
        @"varying vec2 v_texCoord;\n"                                \
        @"void main()\n"                                    \
        @"{\n"                                            \
        @"    gl_FragColor = texture2D(u_texture_1, v_texCoord.xy);\n"    \
        @"}\n";
        
        _vertexString = VERTEX_SHADER_SRC;
        _fragmentString = FRAGMENT_SHADER_SRC;
        
        vertices = new float[sizeof(VERTEX_BUF)];
        textureCoords = new float[sizeof(TEX_COORD_BUF)];
        indices = new unsigned char[sizeof(INDEX_BUF)];
        
        memcpy(vertices, VERTEX_BUF, sizeof(VERTEX_BUF));
        memcpy(textureCoords, TEX_COORD_BUF, sizeof(TEX_COORD_BUF));
        memcpy(indices, INDEX_BUF, sizeof(INDEX_BUF));
        
        vertexCount = sizeof(VERTEX_BUF) / sizeof(float);
        texCoordCount = sizeof(TEX_COORD_BUF) / sizeof(float);
        indexCount = sizeof(INDEX_BUF) / sizeof(unsigned char);
 
    }
    return self;
}

- (void) setTexture:(UIImage*)image {
    _image = image;
}

- (void) draw
{
    if(program == 0) {
        
        program = [MasShaderUtil createProgram:_vertexString fragment:_fragmentString];
        positionHandle = glGetAttribLocation(program, "a_position");
        mvpMatrixHandle = glGetUniformLocation(program, "u_mvpMatrix");
        textureCoordHandle = glGetAttribLocation(program, "a_vertexTexCoord");
        textureHandle = glGetUniformLocation(program, "u_texture_1");
        
        glGenTextures(1, &textureId);
        
        glBindTexture(GL_TEXTURE_2D, textureId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        unsigned char * imageData = [UIImage UIImageToByteArray:_image];
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureId);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _image.size.width, _image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
        delete imageData;
    }
    glUseProgram(program);
    
    glVertexAttribPointer(positionHandle, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(positionHandle);
    
    glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, textureCoords);
    glEnableVertexAttribArray(textureCoordHandle);
    
    _localMVPMatrix = matrix_multiply(_projectionMatrix, _modelMatrix);
    glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const float*)&_localMVPMatrix);
    
    if(textureId != 0)
    {
        glActiveTexture(GL_TEXTURE0);
        glUniform1i(textureHandle, 0);
        glBindTexture(GL_TEXTURE_2D, textureId);
    }
    
    glEnable(GL_DEPTH_TEST);
    
    glDrawElements(GL_TRIANGLES, indexCount, GL_UNSIGNED_BYTE, indices);
    
    glDisableVertexAttribArray(positionHandle);
    glDisableVertexAttribArray(textureCoordHandle);
    
    glDisable(GL_DEPTH_TEST);
    glUseProgram(0);
}
@end
