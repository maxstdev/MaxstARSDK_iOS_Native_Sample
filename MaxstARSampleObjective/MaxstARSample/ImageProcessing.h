//
//  ImageProcessing.h
//  NeonObjective
//
//  Created by Kimseunglee on 2018. 1. 10..
//  Copyright © 2018년 Maxst. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageProcessing : NSObject
+ (void) timeCheck:(void (^)(void))block;

+ (void) ImgUtil_ConvertBGRA888ToY8:(unsigned char*) pyaImg_Data_BGRA8888 Width:(int) piWidth Height:(int) piHeight dest:(unsigned char*) pyaImg_Data_Y8;
//+ (void) neon_convert_bgra_to_grayscale:(uint8_t *) __restrict dest source:(uint8_t *) __restrict src pixelSize:(int) numPixels;
+ (void) ImgUtil_ConvertY8ToBGRA:(unsigned char*) pyaImg_Data_Y8 Width:(int) piWidth Height:(int) piHeight dest:(unsigned char*) pyaImg_Data_BGRA8888;
//+ (void) neon_convert_grayscale_to_bgra:(uint8_t *) __restrict dest source:(uint8_t *) __restrict src pixelSize:(int) numPixels;

+ (void) boxblur:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst ;

+ (void) edgeDection1:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst;
+ (void) edgeDection2:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst;
+ (void) edgeDection3:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst;

+ (void) sharpen:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst;
+ (void) neon_sharpen:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst;
+ (void) vImage_sharpen:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst;

+ (void) halfImage:(int) width Height:(int) height Stride:(int) stride DestStride:(int) destStride Source:(unsigned char *) src Dest:(unsigned char *) dst;
+ (void) neon_halfImage:(int) width Height:(int) height Stride:(int) stride DestStride:(int) destStride Source:(unsigned char *) src Dest:(unsigned char *) dst;
+ (void) vImage_halfImage:(int) width Height:(int) height Stride:(int) stride DestStride:(int) destStride Source:(unsigned char *) src Dest:(unsigned char *) dst;

+ (void) gaussian_3x3:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst;
+ (void) neon_gaussian_3x3:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst;
+ (void) vImage_gaussian_3x3:(int) width Height:(int) height Stride:(int) stride Source:(unsigned char *) src Dest:(unsigned char *) dst;

@end
