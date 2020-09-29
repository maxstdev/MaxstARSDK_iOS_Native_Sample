//
//  BackgroundCameraQuad.h
//  MaxstARSampleObjective
//
//  Created by Kimseunglee on 2018. 3. 5..
//  Copyright © 2018년 Kimseunglee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/SIMD.h>
#import <MaxstARSDKFramework/MaxstARSDKFramework.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import "BaseModel.h"

@interface BackgroundCameraQuad : NSObject
- (instancetype)init:(EAGLContext*) context;
- (void)clearBuffer;
- (void)draw:(MasTrackedImage*)image projectionMatrix:(matrix_float4x4)matrix;
@end
