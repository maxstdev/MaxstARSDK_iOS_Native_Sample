//
//  BackgroundCameraQuad.m
//  MaxstARSampleObjective
//
//  Created by Kimseunglee on 2018. 3. 5..
//  Copyright © 2018년 Kimseunglee. All rights reserved.
//

#import "BackgroundCameraQuad.h"

@interface BackgroundCameraQuad()
{
    NSString *_vertexString;
    NSString *_fragmentString;
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    EAGLContext *openglContext;
    GLuint textureYHandle;
    GLuint textureUVHandle;
    CVPixelBufferRef pixelBuffer;
    
    void * vertices;
    void * indices;
    void * textureCoords;
    
    int vertexCount;
    int indexCount;
    int texCoordCount;
    
    GLuint program;
    GLuint positionHandle;
    GLuint textureCoordHandle;
    GLuint mvpMatrixHandle;
    int textureCount;
    GLuint textureId;
}
@end

@implementation BackgroundCameraQuad

- (instancetype)init:(EAGLContext*) context {
    openglContext = context;
    
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
    
    NSString *vertexString =
    @"attribute vec4 a_position;\n"                                \
    @"uniform mat4 u_mvpMatrix;\n"                                \
    @"attribute vec2 a_vertexTexCoord;\n"                    \
    @"varying vec2 v_texCoord;\n"                        \
    @"void main()\n"                                                    \
    @"{\n"                                                            \
    @"    gl_Position = u_mvpMatrix  * a_position;\n"                    \
    @"    v_texCoord = a_vertexTexCoord;             \n"        \
    @"}\n";
    
    NSString *fragmentString =
    @"precision mediump float;\n"         \
    @"uniform sampler2D SamplerY;\n"                            \
    @"uniform sampler2D SamplerUV;\n"                            \
    @"varying vec2 v_texCoord;\n"                                 \
    @"void main()\n"                                                 \
    @"{\n"                                                         \
    @"    mediump vec3 yuv;" \
    @"    lowp vec3 rgb;"    \
    @"    yuv.x = texture2D(SamplerY, v_texCoord).r;" \
    @"    yuv.yz = texture2D(SamplerUV, v_texCoord).rg - vec2(0.5, 0.5);" \
    @"    rgb = mat3(      1,       1,      1," \
    @"                     0, -.18732, 1.8556," \
    @"               1.57481, -.46813,      0) * yuv;" \
    @"    gl_FragColor = vec4(rgb, 1);" \
    @"}\n";
    
    _vertexString = vertexString;
    _fragmentString = fragmentString;
    
    vertices = new float[sizeof(VERTEX_BUF)];
    textureCoords = new float[sizeof(TEX_COORD_BUF)];
    indices = new unsigned char[sizeof(INDEX_BUF)];
    
    memcpy(vertices, VERTEX_BUF, sizeof(VERTEX_BUF));
    memcpy(textureCoords, TEX_COORD_BUF, sizeof(TEX_COORD_BUF));
    memcpy(indices, INDEX_BUF, sizeof(INDEX_BUF));
    
    vertexCount = sizeof(VERTEX_BUF) / sizeof(float);
    texCoordCount = sizeof(TEX_COORD_BUF) / sizeof(float);
    indexCount = sizeof(INDEX_BUF) / sizeof(unsigned char);
    
    if(_videoTextureCache == nil) {
        CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, openglContext, nil, &_videoTextureCache);
        
        if(error != kCVReturnSuccess) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate");
        }
    }
    return self;
}

- (void) dealloc {
    [self clearBuffer];
}

- (void) cleanUpTextures {
    if (_lumaTexture)
    {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if (_chromaTexture)
    {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void) clearBuffer {
    [self cleanUpTextures];
    CVPixelBufferRelease(pixelBuffer);
    
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
    
    _videoTextureCache = nil;
    pixelBuffer = nil;
}

- (void) draw:(MasTrackedImage *)image projectionMatrix:(matrix_float4x4)matrix {
    if (image == nil)
    {
        return;
    }
    
    if(program == 0) {
        program = [MasShaderUtil createProgram:_vertexString fragment:_fragmentString];
        positionHandle = glGetAttribLocation(program, "a_position");
        mvpMatrixHandle = glGetUniformLocation(program, "u_mvpMatrix");
        textureCoordHandle = glGetAttribLocation(program, "a_vertexTexCoord");
        textureYHandle = glGetUniformLocation(program, "SamplerY");
        textureUVHandle = glGetUniformLocation(program, "SamplerUV");
    }
    
    glUseProgram(program);
    
    glVertexAttribPointer(positionHandle, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(positionHandle);
    
    glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, textureCoords);
    glEnableVertexAttribArray(textureCoordHandle);
    
    glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const float*)&matrix);
    
    if(pixelBuffer == nil) {
        int imageWidth = [image getWidth];
        int imageHeight = [image getHeight];
        NSDictionary *pixelBufferAttributes = @{(__bridge NSString*)kCVPixelBufferIOSurfacePropertiesKey: @{},
                                                (__bridge NSString*)kCVPixelBufferWidthKey:[NSNumber numberWithInt:imageWidth],
                                                (__bridge NSString*)kCVPixelBufferHeightKey:[NSNumber numberWithInt:imageHeight],
                                                (__bridge NSString*)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
                                                (__bridge NSString*)kCVPixelBufferOpenGLESCompatibilityKey:@YES};
        pixelBufferAttributes = @{(__bridge NSString*)kCVPixelBufferIOSurfacePropertiesKey: @{}};
        CVReturn error = CVPixelBufferCreate(kCFAllocatorDefault, imageWidth, imageHeight, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (__bridge CFDictionaryRef)pixelBufferAttributes, &self->pixelBuffer);
        
        if(error != kCVReturnSuccess) {
            NSLog(@"Unable to create CVPixelBuffer");
        }
    } else {
        size_t textureWidth = CVPixelBufferGetWidth(pixelBuffer);
        size_t textureHeight = CVPixelBufferGetHeight(pixelBuffer);
        
        int imageWidth = [image getWidth];
        int imageHeight = [image getHeight];
        if(textureWidth != imageWidth || textureHeight != imageHeight) {
            CVPixelBufferRelease(pixelBuffer);
            pixelBuffer = nil;
        }
    }
    
    if(pixelBuffer != nil) {
        const unsigned char* imagePointer = [image getData];
        int imageWidth = [image getWidth];
        int imageHeight = [image getHeight];
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
        unsigned char* yPlane = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        unsigned char* uvPlane = (unsigned char*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        
        int padding = imageWidth % 64;
        if(padding != 0) {
            unsigned char* offsetYPointer = yPlane;
            unsigned char* offsetPointer = (unsigned char*)imagePointer;
            for(int i = 0; i < imageHeight; i++) {
                memcpy(offsetYPointer, offsetPointer, imageWidth);
                offsetYPointer = offsetYPointer + imageWidth;
                offsetYPointer = offsetYPointer + padding;
                offsetPointer = offsetPointer + imageWidth;
            }
            
            unsigned char* offsetUVPointer = uvPlane;
            for(int i = 0; i<imageHeight/2; i++) {
                memcpy(offsetUVPointer, offsetPointer, imageWidth);
                offsetUVPointer = offsetUVPointer + imageWidth;
                offsetUVPointer = offsetUVPointer + padding;
                offsetPointer = offsetPointer + imageWidth;
            }
            
        } else {
            memcpy(yPlane, imagePointer, imageWidth*imageHeight);
            
            int uvLength = (imageWidth*imageHeight * 3 / 2) - imageWidth*imageHeight;
            const unsigned char* uvPointer = imagePointer + imageWidth*imageHeight;
            memcpy(uvPlane, uvPointer, uvLength);
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        
        size_t textureWidth = CVPixelBufferGetWidth(pixelBuffer);
        size_t textureHeight = CVPixelBufferGetHeight(pixelBuffer);
        
        if(_videoTextureCache != nil) {
            
            [self cleanUpTextures];
            glActiveTexture(GL_TEXTURE0);
            CVReturn error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               _videoTextureCache,
                                                               pixelBuffer,
                                                               nil,
                                                               GL_TEXTURE_2D,
                                                               GL_RED_EXT,
                                                               GLsizei(textureWidth),
                                                               GLsizei(textureHeight),
                                                               GL_RED_EXT,
                                                               GL_UNSIGNED_BYTE,
                                                               0,
                                                               &_lumaTexture);
            
            if(error != kCVReturnSuccess) {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage");
            }
            glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE));
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE));
            glUniform1i(GLint(textureYHandle), 0);
            
            glActiveTexture(GLenum(GL_TEXTURE1));
            error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               _videoTextureCache,
                                                               pixelBuffer,
                                                               nil,
                                                               GLenum(GL_TEXTURE_2D),
                                                               GL_RG_EXT,
                                                               GLsizei(textureWidth / 2),
                                                               GLsizei(textureHeight / 2),
                                                               GLenum(GL_RG_EXT),
                                                               GLenum(GL_UNSIGNED_BYTE),
                                                               1,
                                                               &_chromaTexture);
            if(error != kCVReturnSuccess) {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage");
            }
            glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE));
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE));
            glUniform1i(GLint(textureUVHandle), 1);
        
        }
        
    }
    glDrawElements(GL_TRIANGLES, indexCount, GL_UNSIGNED_BYTE, indices);
    
    glDisableVertexAttribArray(positionHandle);
    glDisableVertexAttribArray(textureCoordHandle);
    glUseProgram(0);
         
}

@end
