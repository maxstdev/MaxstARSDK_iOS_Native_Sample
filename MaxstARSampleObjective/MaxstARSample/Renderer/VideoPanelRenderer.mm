//
//  MVideoPanelRenderer.m
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 12. 11..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import "VideoPanelRenderer.h"

@interface VideoPanelRenderer()
{
    NSString *_vertexString;
    NSString *_fragmentString;
    int _width;
    int _height;
}
@end

@implementation VideoPanelRenderer
- (instancetype)init {
    self = [super init];
    if (self) {
        _width = 0;
        _height = 0;
        
        float VERTEX_BUF[] =
        {
            -0.5f, 0.5f, 0.0f,   // top left
            -0.5f, -0.5f, 0.0f,   // bottom left
            0.5f, -0.5f, 0.0f,   // bottom right
            0.5f, 0.5f, 0.0f  // top right
        };
        
        unsigned char INDEX_BUF[] =
        {
            1, 0, 3, 3, 2, 1
        };
        
        float TEX_COORD_BUF[] =
        {
            0.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f,
            1.0f, 1.0f,
        };
        
        NSString * VERTEX_SHADER_SRC =
        @"attribute vec4 a_position;\n"                    \
        @"attribute vec2 a_vertexTexCoord;\n"                    \
        @"uniform mat4 u_mvpMatrix;\n"                    \
        @"varying vec2 v_texCoord;\n"                        \
        @"void main()\n"                                        \
        @"{\n"                                                \
        @"    gl_Position = u_mvpMatrix  * a_position;\n"        \
        @"    v_texCoord = a_vertexTexCoord;             \n"        \
        @"}\n";
        
        NSString * FRAGMENT_SHADER_SRC =
        @"precision mediump float;\n"
        @"uniform sampler2D u_texture;\n"                            \
        @"varying vec2 v_texCoord;\n"                                \
        @"void main()\n"                                                \
        @"{\n"                                                        \
        @"    gl_FragColor = texture2D(u_texture, v_texCoord);\n"    \
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

- (void) setVideoSize:(int)width height:(int)height {
    _width = width;
    _height = height;
}

- (void) setVideoTextureId:(GLuint)videoTextureId {
    textureId = videoTextureId;
}

- (void) draw {
    
    if(_width == 0 || _height == 0)
    {
        return;
    }
    
    if (program == 0)
    {
        program = [MasShaderUtil createProgram:_vertexString fragment:_fragmentString];
        
        positionHandle = glGetAttribLocation(program, "a_position");
        textureCoordHandle = glGetAttribLocation(program, "a_vertexTexCoord");
        mvpMatrixHandle = glGetUniformLocation(program, "u_mvpMatrix");
        textureHandle = glGetUniformLocation(program, "u_texture");
    }
    
    if (program == 0)
    {
        return;
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
    
    glDrawElements(GL_TRIANGLES, indexCount, GL_UNSIGNED_BYTE, indices);
    
    glDisableVertexAttribArray(positionHandle);
    glDisableVertexAttribArray(textureCoordHandle);
    
    glUseProgram(0);
}
@end
