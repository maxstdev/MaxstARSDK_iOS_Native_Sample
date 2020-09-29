//
//  VideoCaptureController.h
//  VideoPlayFramework
//
//  Created by Kimseunglee on 2017. 5. 19..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoCaptureController : NSObject<AVPlayerItemOutputPullDelegate>

typedef NS_ENUM(int, MEDIA_STATE) {
    REACHED_END = 5,
    PAUSED = 4,
    STOPPED = 3,
    PLAYING = 2,
    READY = 1,
    NOT_READY = 0,
    ERROR = 6
};

- (bool) open:(NSString *)filePath repeat:(bool)isRepeat isMetal:(bool)isMetal context:(id)context;
- (void) play;
- (void) pause;
- (void) stop;
- (MEDIA_STATE) getState;
- (void) update;
- (int) getVideoWidth;
- (int) getVideoHeight;
- (id <MTLTexture>)getMetalTextureId;
- (GLuint)getOpenglesTextureId;
@end
