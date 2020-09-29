//
//  UIImage+Converter.h
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 7. 6..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface UIImage (Converter)
+ (unsigned char*)UIImageToByteArray:(UIImage*)image;
+ (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *) buffer withWidth:(int) width withHeight:(int) heigh;
@end
