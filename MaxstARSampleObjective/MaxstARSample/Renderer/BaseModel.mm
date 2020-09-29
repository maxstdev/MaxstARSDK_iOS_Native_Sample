//
//  MBaseModel.m
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 12. 10..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import "BaseModel.h"

@implementation BaseModel

- (instancetype)init {
    self = [super init];
    if (self) {
        program = 0;
        positionHandle = -1;
        textureCoordHandle = -1;
        colorHandle = -1;
        mvpMatrixHandle = -1;
        textureHandle = -1;
        textureId = -1;
        _modelMatrix = matrix_identity_float4x4;
        _localMVPMatrix = matrix_identity_float4x4;
        _projectionMatrix = matrix_identity_float4x4;
    }
    return self;
}

- (void) draw {
    
}

- (void) setProjectionMatrix:(matrix_float4x4)projectionMatrix {
    _projectionMatrix = projectionMatrix;
}

- (void) setPoseMatrix:(matrix_float4x4)poseMatrix {
    _modelMatrix = poseMatrix;
}

- (void) setTranslation:(float)x y:(float)y z:(float)z {
    matrix_float4x4 translationMatrix = [MasMatrixUtil translation:x y:y z:z];
    _modelMatrix = matrix_multiply(_modelMatrix, translationMatrix);
}

//- (void) setTranslate:(float)x y:(float)y z:(float)z {
//
//}

- (void) setRotation:(float)x y:(float)y z:(float)z {
    matrix_float4x4 rotationMatrix = [MasMatrixUtil rotation:x y:y z:z];
    _modelMatrix = matrix_multiply(_modelMatrix, rotationMatrix);
}

//- (void) setRotate:(float)angle x:(float)x y:(float)y z:(float)z {
//
//}

- (void) setScale:(float)x y:(float)y z:(float)z {
    matrix_float4x4 scaleMatrix = [MasMatrixUtil scale:x y:y z:z];
    _modelMatrix = matrix_multiply(_modelMatrix, scaleMatrix);
}

@end
