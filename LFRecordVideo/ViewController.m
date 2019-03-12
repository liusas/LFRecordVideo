//
//  ViewController.m
//  LFRecordVideo
//
//  Created by 刘峰 on 2019/1/29.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import "ViewController.h"
#import "LFVideoController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)buttonVideoRecordClick:(id)sender {
    LFVideoController *lfVC = [LFVideoController new];
    [self presentViewController:lfVC animated:YES completion:nil];
}

@end
