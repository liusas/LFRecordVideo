//
//  AVAssetWriterManager.m
//  LFRecordVideo
//
//  Created by 刘峰 on 2019/2/11.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import "AVAssetWriterManager.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface AVAssetWriterManager ()

@property (nonatomic, strong) NSURL *videoUrl;/**< 视频文件存储地址*/
@property (nonatomic, strong) dispatch_queue_t writeQueue;/**< 进行写数据操作的子线程*/

@property (nonatomic, assign) BOOL canWrite;

@property (nonatomic, strong) AVAssetWriter *assetWriter;/**< 媒体数据写入文件的对象*/
@property (nonatomic, strong) AVAssetWriterInput *videoWritterInput;
@property (nonatomic, strong) AVAssetWriterInput *audioWritterInput;

@end

@implementation AVAssetWriterManager

- (instancetype)initWithPath:(NSURL *)path {
    return [self initWithPath:path width:CGRectGetWidth([UIScreen mainScreen].bounds) height:CGRectGetHeight([UIScreen mainScreen].bounds)];
}

- (instancetype)initWithPath:(NSURL *)path width:(CGFloat)width height:(CGFloat)height {
    if (self = [super init]) {
        self.videoUrl = path;
        [self configAVAssetWriter];
    }
    return self;
}

/**
 配置AVAssetWriter对象
 */
- (void)configAVAssetWriter {
    _assetWriter = [AVAssetWriter assetWriterWithURL:self.videoUrl fileType:AVFileTypeMPEG4 error:nil];
    /**< 1设置视频属性*/
    //视频像素数量
    NSInteger numberOfPixels = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].bounds.size.height;
    //每个像素的比特
    CGFloat bitsPerPixel = 6.0;
    //比特率为
    NSInteger bitPerSecond = bitsPerPixel * numberOfPixels;
    //设置码率和帧率
    NSDictionary *compressionProperties = @{
                                           AVVideoAverageBitRateKey: @(bitPerSecond),
                                           AVVideoExpectedSourceFrameRateKey: @(30),
                                           AVVideoMaxKeyFrameIntervalKey: @(30),
                                           AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
                                           };
    //视频属性
    NSDictionary *videoSettings = @{
                                    AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                    AVVideoWidthKey : @([UIScreen mainScreen].bounds.size.height),
                                    AVVideoHeightKey : @([UIScreen mainScreen].bounds.size.width),
                                    AVVideoCompressionPropertiesKey : compressionProperties
                                    };
    
    self.videoWritterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
    self.videoWritterInput.expectsMediaDataInRealTime = YES;
    self.videoWritterInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    
    if ([_assetWriter canAddInput:self.videoWritterInput]) {
        [_assetWriter addInput:self.videoWritterInput];
    }
    
    /**< 2.设置音频属性*/
    NSDictionary *audioSettings = @{
                                    AVEncoderBitRatePerChannelKey : @(28000),
                                    AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                    AVNumberOfChannelsKey : @(1),
                                    AVSampleRateKey : @(22050)
                                    };
    self.audioWritterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
    self.audioWritterInput.expectsMediaDataInRealTime = YES;
    
    if ([_assetWriter canAddInput:self.audioWritterInput]) {
        [_assetWriter addInput:self.audioWritterInput];
    }
}

//开始写入数据
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType
{
    if (sampleBuffer == NULL){
        NSLog(@"empty sampleBuffer");
        return;
    }
    
    @synchronized(self){
        if (self.writeState < RecordStateRecording){
            NSLog(@"not ready yet");
            return;
        }
    }
    
    CFRetain(sampleBuffer);
    dispatch_async(self.writeQueue, ^{
        @autoreleasepool {
            @synchronized(self) {
                if (self.writeState > RecordStateRecording){
                    CFRelease(sampleBuffer);
                    return;
                }
            }
            
            if (!self.canWrite && mediaType == AVMediaTypeVideo) {
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self.canWrite = YES;
            }
            
            
            //写入视频数据
            if (mediaType == AVMediaTypeVideo) {
                if (self.videoWritterInput.readyForMoreMediaData) {
                    BOOL success = [self.videoWritterInput appendSampleBuffer:sampleBuffer];
                    if (!success) {
                        @synchronized (self) {
                            [self stopWrite];
                            [self destroyAssetWriter];
                        }
                    }
                }
            }
            
            //写入音频数据
            if (mediaType == AVMediaTypeAudio) {
                if (self.audioWritterInput.readyForMoreMediaData) {
                    BOOL success = [self.audioWritterInput appendSampleBuffer:sampleBuffer];
                    if (!success) {
                        @synchronized (self) {
                            [self stopWrite];
                            [self destroyAssetWriter];
                        }
                    }
                }
            }
            
            CFRelease(sampleBuffer);
        }
    } );
}

- (void)startWrite {
    self.writeState = RecordStateRecording;
    if (!self.assetWriter) {
        [self configAVAssetWriter];
    }
}

- (void)stopWrite {
    self.writeState = RecordStateFinish;
    
    __weak __typeof(self)weakSelf = self;
    if(_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting){
        dispatch_async(self.writeQueue, ^{
            [weakSelf.assetWriter finishWritingWithCompletionHandler:^{
                ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
                [lib writeVideoAtPathToSavedPhotosAlbum:weakSelf.videoUrl completionBlock:^(NSURL *assetURL, NSError *error) {
                    NSLog(@"assetUrl = %@", assetURL);
                    if (!error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(AVAssetWriterManager:didFinishWritting:)]) {
                                [weakSelf.delegate AVAssetWriterManager:weakSelf didFinishWritting:weakSelf.videoUrl];
                            }
                        });
                    } else {
                        NSLog(@"error = %@", error);
                    }
                }];
            }];
        });
    }
}

- (void)destroyAssetWriter {
    self.assetWriter = nil;
    self.videoWritterInput = nil;
    self.audioWritterInput = nil;
    self.videoUrl = nil;
}

- (void)dealloc {
    [self destroyAssetWriter];
}

- (dispatch_queue_t)writeQueue {
    if (!_writeQueue) {
        //手动创建串行队列
        _writeQueue = dispatch_queue_create("captureNewFrame", DISPATCH_QUEUE_SERIAL);
    }
    return _writeQueue;
}

@end
