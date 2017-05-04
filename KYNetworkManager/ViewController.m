//
//  ViewController.m
//  KYNetworkManager
//
//  Created by Jeffrey hu on 17/3/31.
//  Copyright © 2017年 Jeffrey hu. All rights reserved.
//

#import "ViewController.h"
#import "KYNetwork.h"
#import <UAProgressView.h>

static NSString *const downloadUrl = @"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UAProgressView *progressView = [[UAProgressView alloc]init];
    progressView.frame = CGRectMake(100, 100, 240, 240);
    progressView.borderWidth = 3.0;
    progressView.fillOnTouch = YES;
    [self.view addSubview:progressView];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80.0, 32.0)];
    textLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:32];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.textColor = progressView.tintColor;
    textLabel.backgroundColor = [UIColor clearColor];
    progressView.centralView = textLabel;
    
    
    
    [KYNetworkConfig sharedConfig].timeoutInterval = 10;
    [KYNetworkConfig sharedConfig].debugLogEnabled = YES;
    
#if 0
    [[KYNetworkManager sharedManager] GET:@"http://api.staging.kangyu.co/v3/cities/active?locale=en-US" parameters:nil success:^(id responseObject) {
        
    } failure:^(NSError *error, NSString *errorMessage) {
        
    }];
#endif
    
    [[KYNetworkManager sharedManager] GET:@"http://api.staging.kangyu.co/v3/cities/active?locale=en-US" parameters:nil responseCache:^(id responseCache) {
        NSLog(@"responseCache = %@", responseCache);
    } success:nil failure:nil];
    
#if 0
    
    [[KYNetworkManager sharedManager] download:downloadUrl fileDir:@"Download" progress:^(NSProgress *progress) {
        CGFloat stauts = 100.f * progress.completedUnitCount/progress.totalUnitCount;
        NSLog(@"status = %lf", stauts);
        progressView.progress = stauts / 100.f;
        progressView.progressChangedBlock = ^(UAProgressView *progressView, CGFloat progress){
            [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%2.0f%%", progress * 100]];
        };
        
    } success:^(NSString *filePath) {
        NSLog(@"filePath = %@", filePath);
        progressView.progress = 1;
        progressView.progressChangedBlock = ^(UAProgressView *progressView, CGFloat progress){
            [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"100%%"]];
        };
    } failure:nil];
    
#endif
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
