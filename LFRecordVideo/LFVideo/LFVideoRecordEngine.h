//
//  LFVideoRecordEngine.h
//  LFRecordVideo
//
//  Created by 刘峰 on 2019/2/12.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class LFVideoRecordEngine;
NS_ASSUME_NONNULL_BEGIN

@protocol LFVideoRecordEngineDelegate <NSObject>

- (void)updateProgress:(CGFloat)progress;

- (void)videoRecordDidFinish:(LFVideoRecordEngine *)videoRecordEngine andVideoUrl:(NSURL *)videoUrl;

@end

@interface LFVideoRecordEngine : NSObject

@property (nonatomic, weak) id<LFVideoRecordEngineDelegate> delegate;

//捕获到的视频呈现的layer
- (AVCaptureVideoPreviewLayer *)previewLayer;

/**
 初始化视频录制参数
 */
- (void)setUpRecordEngine;

/**
 开始录音
 */
- (void)startRecord;

/**
 结束录音
 */
- (void)stopRecord;

/**
 完成录制
 */
- (void)finishRecord;

/**
 切换前后摄像头
 */
- (void)turnCameraInputDevice;
@end

NS_ASSUME_NONNULL_END
