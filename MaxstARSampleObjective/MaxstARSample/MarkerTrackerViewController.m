//
//  MarkerTrackerViewController.m
//  MaxstARSampleObjective
//
//  Created by Kimseunglee on 2018. 3. 15..
//  Copyright © 2018년 Kimseunglee. All rights reserved.
//

#import "MarkerTrackerViewController.h"
#import "UIImage+Converter.h"
#import <MaxstARSDKFramework/MaxstARSDKFramework.h>
#import "TexturedCube.h"
#import "BackgroundCameraQuad.h"

@interface MarkerTrackerViewController ()
{
    TexturedCube *texturedCube;
    BackgroundCameraQuad *backgroundCameraQuad;
    
    MasCameraDevice *cameraDevice;
    float screenSizeWidth;
    float screenSizeHeight;
    MasTrackerManager *trackingManager;
    
    MasResultCode cameraResultCode;
}
@property (strong, nonatomic) IBOutlet UILabel *markerLabel;

@end

@implementation MarkerTrackerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    trackingManager = [[MasTrackerManager alloc] init];
    cameraDevice = [[MasCameraDevice alloc] init];
    
    [self setPreferredFramesPerSecond:60];
    
    [self setupGL];
    
    texturedCube = [[TexturedCube alloc] init];

    NSString *maxstAR_cubePath = [[NSBundle mainBundle] pathForResource:@"MaxstAR_Cube" ofType:@"png" inDirectory:@"data/Texture"];
    UIImage *maxst_cubeImage = [UIImage imageWithContentsOfFile:maxstAR_cubePath];
    [texturedCube setTexture:maxst_cubeImage];
    
    GLKView *glKitview = (GLKView *)self.view;
    backgroundCameraQuad = [[BackgroundCameraQuad alloc] init:glKitview.context];

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
    [trackingManager destroyTracker];
    [MasMaxstAR deinit];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pauseAR
{
    [trackingManager stopTracker];
    [cameraDevice stop];
}

- (void)enterBackground
{
    [self pauseAR];
}

- (void)resumeAR
{
    [self openCamera];
    [trackingManager startTracker:TRACKER_TYPE_MARKER];
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

    [trackingManager startTracker:TRACKER_TYPE_MARKER];
    
    [trackingManager loadTrackerData];
}

- (IBAction)clickedNormalMode:(id)sender {
    [trackingManager setTrackingOption:NORMAL_TRACKING];
}

- (IBAction)clickedEnhancedMode:(id)sender {
    [trackingManager setTrackingOption:ENHANCED_TRACKING];
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
    
    glEnable(GL_DEPTH_TEST);
    matrix_float4x4 projectionMatrix = [cameraDevice getProjectionMatrix];
    int trackingCount = [result getCount];
    
    NSString *recognizeID = @"Recognized Marker ID : ";
    if(trackingCount > 0)
    {
        for (int i = 0; i < trackingCount; i++)
        {
            MasTrackable *trackable = [result getTrackable:i];
            
            recognizeID = [[NSString alloc] initWithFormat:@"%@ %@,", recognizeID, [trackable getId]];
            
            [texturedCube setProjectionMatrix:projectionMatrix];
            [texturedCube setPoseMatrix:[trackable getPose]];
            [texturedCube setTranslation:0.0f y:0.0f z:-0.05f];
            [texturedCube setScale:1.0f y:1.0f z:0.1f];
            [texturedCube draw];
        }
    }
    
    glDisable(GL_DEPTH_TEST);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.markerLabel.text = recognizeID;
    });
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
