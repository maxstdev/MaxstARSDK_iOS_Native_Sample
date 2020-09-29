//
//  MChromakeyVideoPanelRenderer.h
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 12. 11..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseModel.h"

@interface ChromakeyVideoPanelRenderer : BaseModel

- (void) setVideoSize:(int)width height:(int)height;
- (void) setVideoTextureId:(GLuint)textureId;
@end
