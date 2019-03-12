//
//  AVAssetWriterManager.h
//  LFRecordVideo
//
//  Created by 刘峰 on 2019/2/11.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVAssetWriterManager;
//录制状态
typedef NS_ENUM(NSInteger, RecordState) {
    RecordStatePrepareRecording = 0,
    RecordStateRecording,
    RecordStateFinish,
    RecordStateFailed,
};

@protocol AVAssetWritterDelegate <NSObject>

- (void)AVAssetWriterManager:(AVAssetWriterManager *)manager didFinishWritting:(NSURL *)videoUrl;

@end

NS_ASSUME_NONNULL_BEGIN

@interface AVAssetWriterManager : NSObject

@property (nonatomic, assign) RecordState writeState;
@property (nonatomic, weak) id<AVAssetWritterDelegate> delegate;

- (instancetype)initWithPath:(NSURL *)path;
- (instancetype)initWithPath:(NSURL *)path width:(CGFloat)width height:(CGFloat)height;

- (void)startWrite;
- (void)stopWrite;
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType;
- (void)destroyAssetWriter;
@end

NS_ASSUME_NONNULL_END
