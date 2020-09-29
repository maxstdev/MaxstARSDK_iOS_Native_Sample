//
//  AppDelegate.h
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 6. 14..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (void)lockOrientation:(UIInterfaceOrientationMask)orientation;
+ (void)lockOrientation:(UIInterfaceOrientationMask)orientation andRotateTo:(UIInterfaceOrientation)rotateOrientation;
@end

