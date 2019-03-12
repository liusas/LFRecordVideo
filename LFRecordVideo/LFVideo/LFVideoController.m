//
//  LFVideoController.m
//  LFRecordVideo
//
//  Created by 刘峰 on 2019/1/30.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import "LFVideoController.h"
#import "LFVideoView.h"
#import "FMVideoPlayController.h"

@interface LFVideoController ()

@end

@implementation LFVideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    __weak typeof(self) weakSelf = self;
    
    LFVideoView *videoView = [[LFVideoView alloc] initWithFrame:self.view.bounds];
    videoView.dismissBlock = ^{
        [weakSelf backAction];
    };
    videoView.finishBlock = ^(NSURL * _Nonnull videoUrl) {
        [weakSelf playRecordWithUrl:videoUrl];
    };
    [self.view addSubview:videoView];
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)playRecordWithUrl:(NSURL *)videoUrl {
    FMVideoPlayController *playVC = [[FMVideoPlayController alloc] init];
    playVC.videoUrl =  videoUrl;
    [self presentViewController:playVC animated:YES completion:nil];
//    [self.navigationController pushViewController:playVC animated:YES];
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
