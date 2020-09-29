//
//  ImageTrackerViewController.m
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 6. 14..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import "ImageTrackerViewController.h"
#import <MaxstVideoFramework/MaxstVideoFramework.h>
#import "UIImage+Converter.h"
#import <MaxstARSDKFramework/MaxstARSDKFramework.h>
#import "ColoredCube.h"
#import "TexturedCube.h"
#import "ChromakeyVideoPanelRenderer.h"
#import "VideoPanelRenderer.h"
#import "BackgroundCameraQuad.h"

@interface ImageTrackerViewController ()
{
    VideoPanelRenderer *videoPanelRenderer;
    ChromakeyVideoPanelRenderer *chromakeyVideoPanelRenderer;
    ColoredCube *coloredCube;
    TexturedCube *texturedCube;
    BackgroundCameraQuad *backgroundCameraQuad;
    
    MasCameraDevice *cameraDevice;
    float screenSizeWidth;
    float screenSizeHeight;
    MasTrackerManager *trackingManager;
    
    MasResultCode cameraResultCode;
    
    VideoCaptureController *videoCaptureController;
    VideoCaptureController *chromakeyVideoCaptureController;
}
@property (strong, nonatomic) IBOutlet UISwitch *extendSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *multiSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *normalSwitch;
@end

@implementation ImageTrackerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.extendSwitch setOn:false];
    [self.multiSwitch setOn:false];
    [self.normalSwitch setOn:true];
    
    trackingManager = [[MasTrackerManager alloc] init];
    [trackingManager setTrackingOption:NORMAL_TRACKING];
    cameraDevice = [[MasCameraDevice alloc] init];
    
    [self setPreferredFramesPerSecond:60];
    
    [self setupGL];

    texturedCube = [[TexturedCube alloc] init];
    coloredCube = [[ColoredCube alloc] init];
    videoPanelRenderer = [[VideoPanelRenderer alloc] init];
    chromakeyVideoPanelRenderer = [[ChromakeyVideoPanelRenderer alloc] init];

    NSString *moviePath1 = [[NSBundle mainBundle] pathForResource:@"VideoSample" ofType:@"mp4" inDirectory:@"data/Video"];

    NSString *moviePath2 = [[NSBundle mainBundle] pathForResource:@"ShutterShock" ofType:@"mp4" inDirectory:@"data/Video"];
    
    NSString *maxstAR_cubePath = [[NSBundle mainBundle] pathForResource:@"MaxstAR_Cube" ofType:@"png" inDirectory:@"data/Texture"];

    UIImage *maxst_cubeImage = [UIImage imageWithContentsOfFile:maxstAR_cubePath];
    [texturedCube setTexture:maxst_cubeImage];

    videoCaptureController = [[VideoCaptureController alloc] init];
    chromakeyVideoCaptureController = [[VideoCaptureController alloc] init];

    GLKView *glKitview = (GLKView *)self.view;
    backgroundCameraQuad = [[BackgroundCameraQuad alloc] init:glKitview.context];
    [videoCaptureController open:moviePath1 repeat:true isMetal:false context:glKitview.context];
    [chromakeyVideoCaptureController open:moviePath2 repeat:true isMetal:false context:glKitview.context];

    [videoPanelRenderer setVideoSize:[videoCaptureController getVideoWidth] height:[videoCaptureController getVideoHeight]];
   
    [chromakeyVideoPanelRenderer setVideoSize:[chromakeyVideoCaptureController getVideoWidth] height:[chromakeyVideoCaptureController getVideoHeight]];
    
     [self startEngine];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(pauseAR)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(enterBackground)
     name:UIApplicationDidEnterBackgroundNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(resumeAR)
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self pauseAR];
    [videoCaptureController stop];
    [chromakeyVideoCaptureController stop];
    [trackingManager destroyTracker];
    [MasMaxstAR deinit];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (IBAction)switchNormalImage:(id)sender {
    [self.extendSwitch setOn:false];
    [self.multiSwitch setOn:false];
    [self.normalSwitch setOn:true];
    
    [trackingManager setTrackingOption:NORMAL_TRACKING];
}
- (IBAction)switchMultiImage:(id)sender {
    [self.extendSwitch setOn:false];
    [self.multiSwitch setOn:true];
    [self.normalSwitch setOn:false];
    
    [trackingManager setTrackingOption:MULTI_TRACKING];
}
- (IBAction)switchExtendImage:(id)sender {
    [self.extendSwitch setOn:true];
    [self.multiSwitch setOn:false];
    [self.normalSwitch setOn:false];
    
    [trackingManager setTrackingOption:EXTENDED_TRACKING];
}

- (void)pauseAR
{
    [trackingManager stopTracker];
    [cameraDevice stop];
    [videoCaptureController pause];
    [chromakeyVideoCaptureController pause];
}

- (void)enterBackground
{
    [self pauseAR];
}

- (void)resumeAR
{
    [self openCamera];
    [trackingManager startTracker:TRACKER_TYPE_IMAGE];
}

- (void)setupGL
{
    GLKView *glKitview = (GLKView *)self.view;
    glKitview.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    glKitview.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    glKitview.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:glKitview.context];
    
    glClearColor(0, 0, 0, 1);
    screenSizeWidth = [[UIScreen mainScreen] nativeBounds].size.width;
    screenSizeHeight = [[UIScreen mainScreen] nativeBounds].size.height;
    
    [MasMaxstAR onSurfaceChanged:screenSizeWidth height:screenSizeHeight];
}

- (void)openCamera
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger resolution = [userDefaults integerForKey:@"CameraResolution"];
    
    if(resolution == 0)
    {
        resolution = 640;
        [userDefaults setInteger:640 forKey:@"CameraResolution"];
    }
    
    if(resolution == 1280) {
        cameraResultCode = [cameraDevice start:0 width:1280 height:720];
    } else if(resolution == 640) {
        cameraResultCode = [cameraDevice start:0 width:640 height:480];
    } else if(resolution == 1920) {
        cameraResultCode = [cameraDevice start:0 width:1920 height:1080];
    }
}
    
- (void)startEngine
{
    [MasMaxstAR setLicenseKey:@"RrQzq6y+JDaZ2ImXrj8g4tkF5NETEewL3uWXk8/KPUY="];

    [self openCamera];

    [self setStatusBarOrientaionChange];
    
    NSString *blocksTrackerMapPath = [[NSBundle mainBundle] pathForResource:@"Blocks" ofType:@"2dmap" inDirectory:@"data/SDKSample"];
    NSString *glacierTrackerMapPath = [[NSBundle mainBundle] pathForResource:@"Glacier" ofType:@"2dmap" inDirectory:@"data/SDKSample"];
    NSString *legoTrackerMapPath = [[NSBundle mainBundle] pathForResource:@"Lego" ofType:@"2dmap" inDirectory:@"data/SDKSample"];
    
    [trackingManager startTracker:TRACKER_TYPE_IMAGE];
    [trackingManager setTrackingOption:NORMAL_TRACKING];
    [trackingManager addTrackerData:blocksTrackerMapPath];
    [trackingManager addTrackerData:glacierTrackerMapPath];
    [trackingManager addTrackerData:legoTrackerMapPath];

    [trackingManager loadTrackerData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glViewport(0, 0, screenSizeWidth, screenSizeHeight);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    MasTrackingState *trackingState = [trackingManager updateTrackingState];
    MasTrackingResult *result = [trackingState getTrackingResult];
    
    MasTrackedImage *trackedImage = [trackingState getImage];
   
    [backgroundCameraQuad draw:trackedImage projectionMatrix:[cameraDevice getBackgroundPlaneProjectionMatrix]];
    
    matrix_float4x4 projectionMatrix = [cameraDevice getProjectionMatrix];
    int trackingCount = [result getCount];
    if(trackingCount > 0)
    {
        for (int i = 0; i < trackingCount; i++)
        {
            MasTrackable *trackable = [result getTrackable:i];
            
            if([[trackable getName]  isEqual: @"Lego"])
            {
                if([videoCaptureController getState] == PLAYING)
                {
                    [videoCaptureController play];
                    [videoCaptureController update];

                    [videoPanelRenderer setVideoTextureId:[videoCaptureController getOpenglesTextureId]];
                    [videoPanelRenderer setProjectionMatrix:projectionMatrix];
                    [videoPanelRenderer setPoseMatrix:[trackable getPose]];
                    [videoPanelRenderer setTranslation:0.0f y:0.0f z:0.0f];
                    [videoPanelRenderer setScale:[trackable getWidth] y:[trackable getHeight] z:1.0f];
                    [videoPanelRenderer draw];
                }
            }
            else if([[trackable getName]  isEqual: @"Blocks"])
            {
                if([chromakeyVideoCaptureController getState] == PLAYING)
                {
                    [chromakeyVideoCaptureController play];
                    [chromakeyVideoCaptureController update];

                    [chromakeyVideoPanelRenderer setVideoTextureId:[chromakeyVideoCaptureController getOpenglesTextureId]];
                    [chromakeyVideoPanelRenderer setProjectionMatrix:projectionMatrix];
                    [chromakeyVideoPanelRenderer setPoseMatrix:[trackable getPose]];
                    [chromakeyVideoPanelRenderer setTranslation:0.0f y:0.0f z:0.0f];
                    [chromakeyVideoPanelRenderer setScale:[trackable getWidth] y:[trackable getHeight] z:1.0f];
                    [chromakeyVideoPanelRenderer draw];
                }
            }
            else if([[trackable getName]  isEqual: @"Glacier"])
            {
                [texturedCube setProjectionMatrix:projectionMatrix];
                [texturedCube setPoseMatrix:[trackable getPose]];
                [texturedCube setTranslation:0.0f y:0.0f z:-[trackable getHeight]*0.25f*0.5f];
                [texturedCube setScale:[trackable getWidth]*0.25f y:[trackable getHeight]*0.25f z:[trackable getHeight]*0.25f];
                [texturedCube draw];
            }
            else {
                [coloredCube setProjectionMatrix:projectionMatrix];
                [coloredCube setPoseMatrix:[trackable getPose]];
                [coloredCube setTranslation:0.0f y:0.0f z:-[trackable getHeight]*0.25f*0.5f];
                [coloredCube setScale:[trackable getWidth] y:[trackable getHeight] z:[trackable getHeight]*0.25f];
                [coloredCube draw];
            }
        }
    }
    else
    {
        [videoCaptureController pause];
        [chromakeyVideoCaptureController pause];
    }
    
    glDisable(GL_DEPTH_TEST);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self setOrientaionChange];
}

- (void)setOrientaionChange
{
    if(UIDevice.currentDevice.orientation == UIDeviceOrientationPortrait)
    {
        screenSizeWidth = [[UIScreen mainScreen] nativeBounds].size.width;
        screenSizeHeight = [[UIScreen mainScreen] nativeBounds].size.height;
        [MasMaxstAR setScreenOrientation:PORTRAIT_UP];
    }
    else if(UIDevice.currentDevice.orientation == UIDeviceOrientationPortraitUpsideDown)
    {
        screenSizeWidth = [[UIScreen mainScreen] nativeBounds].size.width;
        screenSizeHeight = [[UIScreen mainScreen] nativeBounds].size.height;
        [MasMaxstAR setScreenOrientation:PORTRAIT_DOWN];
    }
    else if(UIDevice.currentDevice.orientation == UIDeviceOrientationLandscapeLeft)
    {
        screenSizeWidth = [[UIScreen mainScreen] nativeBounds].size.height;
        screenSizeHeight = [[UIScreen mainScreen] nativeBounds].size.width;
        [MasMaxstAR setScreenOrientation:LANDSCAPE_LEFT];
    }
    else if(UIDevice.currentDevice.orientation == UIDeviceOrientationLandscapeRight)
    {
        screenSizeWidth = [[UIScreen mainScreen] nativeBounds].size.height;
        screenSizeHeight = [[UIScreen mainScreen] nativeBounds].size.width;
        [MasMaxstAR setScreenOrientation:LANDSCAPE_RIGHT];
    }
    
    [MasMaxstAR onSurfaceChanged:screenSizeWidth height:screenSizeHeight];
}

- (void)setStatusBarOrientaionChange
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(orientation == UIInterfaceOrientationPortrait)
    {
        screenSizeWidth = [[UIScreen mainScreen] nativeBounds].size.width;
        screenSizeHeight = [[UIScreen mainScreen] nativeBounds].size.height;
        [MasMaxstAR setScreenOrientation:PORTRAIT_UP];
    }
    else if(orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        screenSizeWidth = [[UIScreen mainScreen] nativeBounds].size.width;
        screenSizeHeight = [[UIScreen mainScreen] nativeBounds].size.height;
        [MasMaxstAR setScreenOrientation:PORTRAIT_DOWN];
    }
    else if(orientation == UIInterfaceOrientationLandscapeLeft)
    {
        screenSizeWidth = [[UIScreen mainScreen] nativeBounds].size.height;
        screenSizeHeight = [[UIScreen mainScreen] nativeBounds].size.width;
        [MasMaxstAR setScreenOrientation:LANDSCAPE_RIGHT];
    }
    else if(orientation == UIInterfaceOrientationLandscapeRight)
    {
        screenSizeWidth = [[UIScreen mainScreen] nativeBounds].size.height;
        screenSizeHeight = [[UIScreen mainScreen] nativeBounds].size.width;
        [MasMaxstAR setScreenOrientation:LANDSCAPE_LEFT];
    }
    
    [MasMaxstAR onSurfaceChanged:screenSizeWidth height:screenSizeHeight];
}

@end
