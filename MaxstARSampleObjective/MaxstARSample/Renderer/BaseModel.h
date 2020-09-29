//
//  MBaseModel.h
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 12. 10..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/SIMD.h>
#import <MaxstARSDKFramework/MaxstARSDKFramework.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface BaseModel : NSObject
{
    void * vertices;
    void * indices;
    void * textureCoords;
    void * colors;
    
    int vertexCount;
    int indexCount;
    int texCoordCount;
    
    GLuint program;
    GLuint positionHandle;
    GLuint textureCoordHandle;
    GLuint colorHandle;
    GLuint mvpMatrixHandle;
    int textureCount;
    GLuint textureId;
    GLuint textureHandle;
    GLuint vertexBufferObject[4];
    
    matrix_float4x4 _modelMatrix;
    matrix_float4x4 _localMVPMatrix;
    matrix_float4x4 _projectionMatrix;
}

- (void) draw;
- (void) setProjectionMatrix:(matrix_float4x4)projectionMatrix;
- (void) setPoseMatrix:(matrix_float4x4)poseMatrix;
- (void) setTranslation:(float)x y:(float)y z:(float)z;
//- (void) setTranslate:(float)x y:(float)y z:(float)z;
- (void) setRotation:(float)x y:(float)y z:(float)z;
//- (void) setRotate:(float)angle x:(float)x y:(float)y z:(float)z;
- (void) setScale:(float)x y:(float)y z:(float)z;
@end
