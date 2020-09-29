//
//  InstantTrackerViewController.m
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 6. 14..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import "InstantTrackerViewController.h"
#import <MaxstARSDKFramework/MaxstARSDKFramework.h>
#import "TexturedCube.h"
#import "UIImage+Converter.h"
#import "BackgroundCameraQuad.h"
#import "AppDelegate.h"

@interface InstantTrackerViewController ()
{
    TexturedCube *texturedCube;
    BackgroundCameraQuad *backgroundCameraQuad;
    MasCameraDevice *cameraDevice;
    MasSensorDevice *sensorDevice;
    float screenSizeWidth;
    float screenSizeHeight;
    MasTrackerManager *trackingManager;
    
    MasResultCode cameraResultCode;
    
    float panTranslateX;
    float panTranslateY;
    
    float beforeTranslateX;
    float beforeTranslateY;
    
    float touchFirstX;
    float touchFirstY;
    
    float pinchScale;
    
    float rotateValue;
    float rotationValue;
    unsigned char *imageData;
}
@end

@implementation InstantTrackerViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    panTranslateX = 0.0f;
    panTranslateY = 0.0f;
    
    beforeTranslateX = 0.0f;
    beforeTranslateY = 0.0f;
    pinchScale = 0.0f;
    rotateValue = 0.0f;

    trackingManager = [[MasTrackerManager alloc] init];
    cameraDevice = [[MasCameraDevice alloc] init];
    sensorDevice = [[MasSensorDevice alloc] init];
    texturedCube = [[TexturedCube alloc] init];

    [self setupGL];
    
    GLKView *glKitview = (GLKView *)self.view;
    backgroundCameraQuad = [[BackgroundCameraQuad alloc] init:glKitview.context];

    NSString *maxstAR_cubePath = [[NSBundle mainBundle] pathForResource:@"MaxstAR_Cube" ofType:@"png" inDirectory:@"data/Texture"];
    UIImage *maxst_cubeImage = [UIImage imageWithContentsOfFile:maxstAR_cubePath];
    [texturedCube setTexture:maxst_cubeImage];
    
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
    [sensorDevice start];
    
    [self setStatusBarOrientaionChange];
    [trackingManager startTracker:TRACKER_TYPE_INSTANT];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self pauseAR];
    [trackingManager destroyTracker];
    [MasMaxstAR deinit];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)doTrackingState:(id)sender {
    
    UIButton *button = (UIButton*)sender;
    
    if([[[button titleLabel] text]  isEqual: @"Start Tracking"])
    {
        beforeTranslateX = 0.0f;
        beforeTranslateY = 0.0f;
        panTranslateX = 0.0f;
        panTranslateY = 0.0f;
        pinchScale = 0.0f;
        rotateValue = 0.0f;
        
        [trackingManager findSurface];
        [button setTitle:@"Stop Tracking" forState:UIControlStateNormal];
    }
    else if([[[button titleLabel] text]  isEqual: @"Stop Tracking"])
    {
        [trackingManager quitFindingSurface];
        [button setTitle:@"Start Tracking" forState:UIControlStateNormal];
    }
}

- (IBAction)panScreen:(id)sender {
    UIPanGestureRecognizer *pan = (UIPanGestureRecognizer*)sender;
    CGPoint translation = [pan locationInView:self.view];
    
    float x = translation.x;
    float y = translation.y;
    float resolutionWidth = [[UIScreen mainScreen] nativeBounds].size.width;
    float resolutionHeight = [[UIScreen mainScreen] nativeBounds].size.height;
    float realX = 0.0f;
    float realY = 0.0f;
    
    if(UIDevice.currentDevice.orientation == UIDeviceOrientationPortrait)
    {
        realX = (resolutionWidth/self.view.bounds.size.width) * x;
        realY = (resolutionHeight/self.view.bounds.size.height) * y;
    }
    else if(UIDevice.currentDevice.orientation == UIDeviceOrientationLandscapeLeft)
    {
        realX = (resolutionHeight/self.view.bounds.size.width) * x;
        realY = (resolutionWidth/self.view.bounds.size.height) * y;
    }
    else if(UIDevice.currentDevice.orientation == UIDeviceOrientationLandscapeRight)
    {
        realX = resolutionHeight - (resolutionHeight/self.view.bounds.size.width) * x;
        realY = resolutionWidth - (resolutionWidth/self.view.bounds.size.height) * y;
    }

    float screenCoordinate[] = {realX, realY};
    float worldCoordinate[] = {0.0f, 0.0f, 0.0f};
    
    if(pan.state == UIGestureRecognizerStateBegan) {
        [trackingManager getWorldPositionFromScreenCoordinate:screenCoordinate world:worldCoordinate];
        
        touchFirstX = worldCoordinate[0];
        touchFirstY = worldCoordinate[1];
    }
    else if(pan.state == UIGestureRecognizerStateChanged)
    {
        [trackingManager getWorldPositionFromScreenCoordinate:screenCoordinate world:worldCoordinate];
        
        panTranslateX = beforeTranslateX + worldCoordinate[0] - touchFirstX;
        panTranslateY = beforeTranslateY + worldCoordinate[1] - touchFirstY;
    }
    else if(pan.state == UIGestureRecognizerStateEnded)
    {
        beforeTranslateX = panTranslateX;
        beforeTranslateY = panTranslateY;
    }
}
- (IBAction)rotateScreen:(id)sender {
    UIRotationGestureRecognizer *rotate = (UIRotationGestureRecognizer *)sender;
    CGFloat rotation = [rotate rotation];
    rotateValue =  -(rotation * 90.0f);
}
- (IBAction)pinchScreen:(id)sender {
    CGFloat factor = [(UIPinchGestureRecognizer *)sender scale];
    pinchScale = (factor - 1.0f)/2.0f;
}

- (void)pauseAR
{
    [trackingManager stopTracker];
    [cameraDevice stop];
    [sensorDevice stop];
}

- (void)enterBackground
{
    [self pauseAR];
}

- (void)resumeAR
{
    [self openCamera];
    [sensorDevice start];
    [trackingManager startTracker:TRACKER_TYPE_INSTANT];
}

- (void)setupGL
{
    GLKView *glKitview = (GLKView *)self.view;
    glKitview.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    glKitview.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    glKitview.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.preferredFramesPerSecond = 60;
   
    [EAGLContext setCurrentContext:glKitview.context];
    
    screenSizeWidth = [[UIScreen mainScreen] nativeBounds].size.width;
    screenSizeHeight = [[UIScreen mainScreen] nativeBounds].size.height;
    glViewport(0, 0, screenSizeWidth, screenSizeHeight);
    
    [MasMaxstAR onSurfaceChanged:screenSizeWidth height:screenSizeHeight];
    glClearColor(0, 0, 0, 1);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    MasTrackingState *trackingState = [trackingManager updateTrackingState];
    MasTrackingResult *result = [trackingState getTrackingResult];
    
    MasTrackedImage *trackedImage = [trackingState getImage];
    [backgroundCameraQuad draw:trackedImage projectionMatrix:[cameraDevice getBackgroundPlaneProjectionMatrix]];
    
    glEnable(GL_DEPTH_TEST);
    matrix_float4x4 projectionMatrix = [cameraDevice getProjectionMatrix];
    
    for (int i = 0; i < [result getCount]; i++)
    {
        MasTrackable *trackable = [result getTrackable:i];
        
        [texturedCube setProjectionMatrix:projectionMatrix];
        [texturedCube setPoseMatrix:[trackable getPose]];
        [texturedCube setTranslation:panTranslateX y:panTranslateY z:-0.05f];
        [texturedCube setScale:0.3f + pinchScale y:0.3f + pinchScale z:0.01f];
        [texturedCube draw];
    }
    
    glDisable(GL_DEPTH_TEST);
}

- (BOOL)prefersStatusBarHidden {
    return YES;
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
