//
//  SettingTableViewController.m
//  MaxstARSample
//
//  Created by Kimseunglee on 2017. 7. 21..
//  Copyright © 2017년 Kimseunglee. All rights reserved.
//

#import "SettingTableViewController.h"

@interface SettingTableViewController ()
@property (strong, nonatomic) IBOutlet UISwitch *resolution640;
@property (strong, nonatomic) IBOutlet UISwitch *resolution1280;
@property (strong, nonatomic) IBOutlet UISwitch *resolution1920;

@end

@implementation SettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSInteger resolution = [self getSavedCameraResolution];
    
    if(resolution == 640) {
        [_resolution640 setOn:true];
        [_resolution1280 setOn:false];
        [_resolution1920 setOn:false];
    } else if(resolution == 1280) {
        [_resolution640 setOn:false];
        [_resolution1280 setOn:true];
        [_resolution1920 setOn:false];
    } else if(resolution == 1920) {
        [_resolution640 setOn:false];
        [_resolution1280 setOn:false];
        [_resolution1920 setOn:true];
    }
}
    
- (IBAction)changeSwitch640:(id)sender {
    if(_resolution640.isOn) {
        [_resolution640 setOn:true];
        [_resolution1280 setOn:false];
        [_resolution1920 setOn:false];
        [self saveCameraResolution:640];
    }
}
    
- (IBAction)changeSwitch1280:(id)sender {
    if(_resolution1280.isOn) {
        [_resolution640 setOn:false];
        [_resolution1280 setOn:true];
        [_resolution1920 setOn:false];
        [self saveCameraResolution:1280];
    }
}

- (IBAction)changeSwitch1920:(id)sender {
    if(_resolution1920.isOn) {
        [_resolution640 setOn:false];
        [_resolution1280 setOn:false];
        [_resolution1920 setOn:true];
        [self saveCameraResolution:1920];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
- (void)saveCameraResolution:(NSInteger)resolution
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:resolution forKey:@"CameraResolution"];
}
    
- (NSInteger)getSavedCameraResolution {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger resolution = [userDefaults integerForKey:@"CameraResolution"];
    
    if(resolution == 0)
    {
        resolution = 640;
        [userDefaults setInteger:640 forKey:@"CameraResolution"];
    }
    
    return resolution;
}
    

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
    
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

@end
