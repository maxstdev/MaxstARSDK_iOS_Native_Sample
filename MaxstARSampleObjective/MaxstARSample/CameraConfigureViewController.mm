//
//  CameraConfigureViewController.m
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 6. 14..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import "CameraConfigureViewController.h"
#import <MaxstARSDKFramework/MaxstARSDKFramework.h>
#import "BackgroundCameraQuad.h"

typedef enum tagCAMERA_DIRECTION {
    REAR = 0,
    FRONT = 1
} CAMERA_DIRECTION;

@interface CameraConfigureViewController ()
{
    BackgroundCameraQuad *backgroundCameraQuad;
    MasCameraDevice *cameraDevice;
    float screenSizeWidth;
    float screenSizeHeight;
    MasTrackerManager *trackingManager;
    
    MasResultCode cameraResultCode;
    CAMERA_DIRECTION currentCameraDirection;
}
@property (strong, nonatomic) IBOutlet UISwitch *rearSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *frontSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *flashSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *horizontalSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *verticalSwitch;
@end

@implementation CameraConfigureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.rearSwitch setOn:true];
    [self.frontSwitch setOn:false];
    [self.flashSwitch setOn:false];
    [self.horizontalSwitch setOn:false];
    [self.verticalSwitch setOn:false];
    
    trackingManager = [[MasTrackerManager alloc] init];
    cameraDevice = [[MasCameraDevice alloc] init];
    
    [self setupGL];
    
    GLKView *glKitview = (GLKView *)self.view;
    backgroundCameraQuad = [[BackgroundCameraQuad alloc] init:glKitview.context];
    
    currentCameraDirection = REAR;
    
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
    [MasMaxstAR deinit];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)switchDirectionRear:(id)sender {
    [self.rearSwitch setOn:true];
    [self.frontSwitch setOn:false];
    
    if(currentCameraDirection == 1) {
        currentCameraDirection = REAR;
        [self openCamera];
    }
}
- (IBAction)switchDirectionFront:(id)sender {
    [self.rearSwitch setOn:false];
    [self.frontSwitch setOn:true];
    
    if(currentCameraDirection == 0) {
        currentCameraDirection = FRONT;
        [self openCamera];
        
        if(self.flashSwitch.isOn) {
            [self.flashSwitch setOn:false];
        }
    }
}
- (IBAction)switchFlash:(id)sender {
    if(self.frontSwitch.isOn) {
        [self.flashSwitch setOn:false];
    } else {
        [cameraDevice setFlashLightMode:self.flashSwitch.isOn];
    }
}
- (IBAction)switchFlipHorizontal:(id)sender {
    [cameraDevice flipVideo:HORIZONTAL toggle:self.horizontalSwitch.isOn];
}
- (IBAction)switchFlipVertical:(id)sender {
    [cameraDevice flipVideo:VERTICAL toggle:self.verticalSwitch.isOn];
}

- (void)pauseAR
{
    [cameraDevice stop];
}

- (void)enterBackground
{
    [self pauseAR];
}

- (void)resumeAR
{
    [self openCamera];
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
    
    [cameraDevice stop];
    
    if(resolution == 1280) {
        cameraResultCode = [cameraDevice start:currentCameraDirection width:1280 height:720];
    } else if(resolution == 640) {
        cameraResultCode = [cameraDevice start:currentCameraDirection width:640 height:480];
    } else if(resolution == 1920) {
        cameraResultCode = [cameraDevice start:currentCameraDirection width:1920 height:1080];
    }
    
    GLKView *glKitview = (GLKView *)self.view;
//    backgroundCameraQuad = [[BackgroundCameraQuad alloc] init:glKitview.context];
}

- (void)startEngine
{
    [MasMaxstAR setLicenseKey:@"RrQzq6y+JDaZ2ImXrj8g4tkF5NETEewL3uWXk8/KPUY="];
    
    [self openCamera];
    
    [self setStatusBarOrientaionChange];
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
    MasTrackedImage *trackedImage = [trackingState getImage];
    [backgroundCameraQuad draw:trackedImage projectionMatrix:[cameraDevice getBackgroundPlaneProjectionMatrix]];
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

