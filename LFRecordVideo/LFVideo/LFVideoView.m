//
//  LFVideoView.m
//  LFRecordVideo
//
//  Created by 刘峰 on 2019/1/31.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import "LFVideoView.h"
#import <AVFoundation/AVFoundation.h>
#import "LFVideoProgressLayer.h"
#import "AVAssetWriterManager.h"
#import "LFVideoRecordEngine.h"

static CGFloat const Record_Button_Width = 70.f;//录制按钮的宽度

@interface LFVideoView () <LFVideoRecordEngineDelegate>

@property (nonatomic, strong) UIButton *closeBtn;/**< 关闭按钮*/
@property (nonatomic, strong) UIButton *recordButton;/**< 录制按钮*/
@property (nonatomic, strong) LFVideoProgressLayer *progressLayer;/**< 录制时的圆圈进度*/
@property (nonatomic, strong) UIButton *cancelButton;/**< 取消录制按钮*/
@property (nonatomic, strong) UIButton *finishButton;/**< 录制完成按钮*/
@property (nonatomic, strong) UIButton *turnCamera;/**< 切换镜头按钮*/



@property (nonatomic, strong) NSURL *videoUrl;/**< 视频文件地址*/

@property (nonatomic, strong) LFVideoRecordEngine *recordEngine;/**< 视频录制对象*/

@end

@implementation LFVideoView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setUp];
        [self setUpConstraints];
    }
    return self;
}

- (void)setUp {
    [self addSubview:self.closeBtn];
    [self addSubview:self.recordButton];
    [self.recordButton.layer addSublayer:self.progressLayer];
//    [self addSubview:self.cancelButton];
//    [self addSubview:self.finishButton];
    [self addSubview:self.turnCamera];
    
    [self.layer insertSublayer:[self.recordEngine previewLayer] atIndex:0];
}

/**
 适配
 */
- (void)setUpConstraints {
    self.turnCamera.frame = CGRectMake(CGRectGetWidth(self.frame)-20-25,
                                       30,
                                       25,
                                       21);
    self.recordButton.frame = CGRectMake(CGRectGetWidth(self.frame)/2-Record_Button_Width/2,
                                         CGRectGetHeight(self.frame)-60-Record_Button_Width,
                                         Record_Button_Width,
                                         Record_Button_Width);
    self.closeBtn.frame = CGRectMake((self.recordButton.frame.origin.x-32)/2,
                                     self.recordButton.frame.origin.y+(self.recordButton.frame.size.height-32)/2,
                                     32,
                                     32);
    
}

#pragma mark - Button response
/**
 切换镜头按钮点击事件
 */
- (void)turnCameraButtonClick {
    [self.recordEngine turnCameraInputDevice];
}

/**
 关闭录制页面按钮点击事件
 */
- (void)closeButtonClick {
    if (self.dismissBlock) {
        self.dismissBlock();
    }
}

/**
 取消录制按钮
 */
- (void)cancelButtonClick {
    
}

/**
 完成录制按钮
 */
- (void)finishButtonClick {
    [self.recordEngine finishRecord];
}

/**
 开始录制
 */
- (void)startRecord {
    [self.recordEngine startRecord];
    [UIView animateWithDuration:.5f animations:^{
        self.recordButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
    }];
}

/**
 结束录制
 */
- (void)stopRecord {
    [self.recordEngine stopRecord];
    self.recordButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
}

#pragma mark - LFVideoRecordEngineDelegate
- (void)updateProgress:(CGFloat)progress {
    self.progressLayer.progress = progress;
}

- (void)videoRecordDidFinish:(id)videoRecordEngine andVideoUrl:(NSURL *)videoUrl {
    self.finishBlock(videoUrl);
}

#pragma mark - Getters
/**< 切换镜头按钮*/
-(UIButton *)turnCamera{
    if (!_turnCamera) {
        _turnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
        [_turnCamera setImage:[UIImage imageNamed:@"turnCamera"] forState:UIControlStateNormal];
        [_turnCamera addTarget:self action:@selector(turnCameraButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _turnCamera;
}

/**< 关闭按钮*/
-(UIButton *)closeBtn{
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

/**< 录制按钮*/
-(UIButton *)recordButton{
    if (!_recordButton) {
        _recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_recordButton addTarget:self action:@selector(startRecord) forControlEvents:UIControlEventTouchDown];
        [_recordButton addTarget:self action:@selector(stopRecord) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    }
    return _recordButton;
}

- (LFVideoProgressLayer *)progressLayer {
    if (!_progressLayer) {
        _progressLayer = [[LFVideoProgressLayer alloc] initWithProgressFrame:CGRectMake(0, 0, Record_Button_Width, Record_Button_Width)];
    }
    return _progressLayer;
}

/**< 取消录制按钮*/
-(UIButton *)cancleBtn{
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setImage:[UIImage imageNamed:@"turnVideoBack"] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
        
        _cancelButton.layer.masksToBounds = YES;
        _cancelButton.layer.cornerRadius = 25;
        _cancelButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _cancelButton.frame = CGRectMake(0, 0, 50, 50);
    }
    return _cancelButton;
}

/**< 录制完成按钮*/
-(UIButton *)finishButton{
    if (!_finishButton) {
        _finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_finishButton setImage:[UIImage imageNamed:@"turnVideoDone"] forState:UIControlStateNormal];
        [_finishButton addTarget:self action:@selector(finishButtonClick) forControlEvents:UIControlEventTouchUpInside];
        
        _finishButton.layer.masksToBounds = YES;
        _finishButton.layer.cornerRadius = 25;
        _finishButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _finishButton.frame = CGRectMake(0, 0, 50, 50);
    }
    return _finishButton;
}

- (LFVideoRecordEngine *)recordEngine {
    if (!_recordEngine) {
        _recordEngine = [[LFVideoRecordEngine alloc] init];
        _recordEngine.delegate = self;
    }
    return _recordEngine;
}

@end
