//
//  LFVideoRecordEngine.m
//  LFRecordVideo
//
//  Created by 刘峰 on 2019/2/12.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import "LFVideoRecordEngine.h"
#import "LFVideoProgressLayer.h"
#import "AVAssetWriterManager.h"

static CGFloat const MaxVideoRecordTime = 10.f;//最长录制时长
static CGFloat const TimerRefreshFrequency = 0.05;//计时器刷新频率

@interface LFVideoRecordEngine () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVAssetWritterDelegate>

@property (nonatomic, strong) AVCaptureSession *session;/**< 捕捉会话*/
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;/**< 视频预览视图*/
@property (nonatomic, strong) dispatch_queue_t captureQueue;/**< 创建队列*/
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;/**< 记录视频输入源*/
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;/**< 记录音频输入源*/
@property (nonatomic, strong) AVCaptureConnection *videoConnection;/**< 视频连接*/
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;/**< 记录视频输出*/
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;/**< 记录音频输出*/
@property (nonatomic, strong) AVAssetWriterManager *assetWriterManger;/**< 分离出来的写数据操作*/
@property (nonatomic, strong) NSURL *videoUrl;/**< 视频文件地址*/

@property (nonatomic, assign) BOOL isRecording;/**< 判断是否正在录制*/
@property (nonatomic, assign) NSTimer *timer;/**< 计时器*/
@property (nonatomic, assign) CGFloat recordTimeLength;/**< 录制时长*/

@end

@implementation LFVideoRecordEngine

- (instancetype)init {
    if (self = [super init]) {
        [self initData];
        [self setUpRecordEngine];
    }
    return self;
}

- (void)initData {
    self.isRecording = NO;
    self.recordTimeLength = 0;
}

- (void)setUpRecordEngine {
    [self setUpVideo];
    [self setUpAudio];
    [self setUpVideoPreviewLayerWithType];
    [self.session startRunning];
    [self setUpAVAssetWriterManager];
}

#pragma mark - Private methods

/**
 添加视频输入
 */
- (void)setUpVideo {
    [self checkAuthorizationStatus];//检测用户权限
    
    //1.1获取视频输入摄像设备
    AVCaptureDevice *captureDevice = [self getAVCaptureDeviceWithPosition:AVCaptureDevicePositionBack];
    //1.2创建视频输入源
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:nil];
    //1.3将视频输入源添加到会话
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    //1.4设置视频输出
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES;//在捕获到下一帧之前,始终丢弃未处理的任何视频帧,用来处理在捕获到新帧时,如果线程阻塞了,立即丢弃当前未处理的视频帧.
    
    NSDictionary *settingDic = [[NSDictionary alloc] initWithObjectsAndKeys:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange), kCVPixelBufferPixelFormatTypeKey, nil];
    [self.videoOutput setVideoSettings:settingDic];
    
    //此方法是指将在captureQueue的调度队列上调用captureoutput:didOutputSampleBuffer:FromConnection:Delegate委托方法,在捕获到新帧时,如果线程阻塞了,立即丢弃当前未处理的视频帧,captureQueue必须是串行队列
    [self.videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
    
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
}


/**
 添加音频输入源
 */
- (void)setUpAudio {
    //2.1获取音频输入设备
    AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    //2.2创建音频输入源
    self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    //2.3将音频输入源添加到会话
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    
    //2.4设置音频输出
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    
    if ([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
}


/**
 添加视频预览层
 */
- (void)setUpVideoPreviewLayerWithType {
    self.previewLayer.frame = [UIScreen mainScreen].bounds;
}


/**
 初始化AVAssetWriterManager
 */
- (void)setUpAVAssetWriterManager {
    [self clearFiles];//在开始录下一个视频之前,先把上一个视频文件给删了
    
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSString *videoName = [NSString stringWithFormat:@"videoRecord%.0f.mp4", timeInterval];
    self.videoUrl = [NSURL fileURLWithPath:[[self getFilePath] stringByAppendingPathComponent:videoName]];
    self.assetWriterManger = [[AVAssetWriterManager alloc] initWithPath:self.videoUrl];
}

/**
 获取视频文件存储路径
 
 @return 视频文件存储路径
 */
- (NSString *)getFilePath {
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *videoDir = [cacheDir stringByAppendingPathComponent:@"videoRecord"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:videoDir]) {
        [fileManager createDirectoryAtPath:videoDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return videoDir;
}


/**
 清空视频文件
 */
- (void)clearFiles {
    NSLog(@"清空视频文件%@", [[NSFileManager defaultManager] removeItemAtPath:[self getFilePath] error:nil] ? @"成功" : @"失败");
}

/**
 检查用户权限
 */
- (void)checkAuthorizationStatus {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusNotDetermined: {//用户尚未确认这个权限
            NSLog(@"用户尚未确认这个权限AVAuthorizationStatusNotDetermined");
            /**<判断手机是否同意开启相机访问权限,若没同意则弹出提示框让用户确认*/
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                NSLog(@"granted --- %d currentThread : %@",granted,NSThread.currentThread);
            }];
        }
            break;
        case AVAuthorizationStatusRestricted: {//系统不允许用户使用媒体捕获设备
            NSLog(@"系统不允许用户使用媒体捕获设备AVAuthorizationStatusRestricted");
        }
            break;
        case AVAuthorizationStatusDenied: {//用户拒绝使用媒体捕获设备
            NSLog(@"用户拒绝使用媒体捕获设备AVAuthorizationStatusDenied");
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"没有权限" message:@"该功能需要授权使用你的相机" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleCancel handler:nil];
            
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"授权" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                
                if (@available(iOS 10.0, *)) {
                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
                        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                            
                        }];
                    }
                } else {
                    if( [[UIApplication sharedApplication]canOpenURL:url] ) {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }
            }];
            
            [alertController addAction:cancelAction];
            [alertController addAction:confirmAction];
            
            [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
        }
            break;
        case AVAuthorizationStatusAuthorized: {//用户同意应用使用媒体捕获设备
            NSLog(@"用户同意应用使用媒体捕获设备AVAuthorizationStatusAuthorized");
        }
            break;
        default:
            break;
    }
}


/**
 获取指定镜头设备
 iOS10以后的版本可以使用AVCaptureDeviceDiscoverySession获得可用的后置双镜头,在iOS10以前只能获取广角镜头
 */
- (AVCaptureDevice *)getAVCaptureDeviceWithPosition:(AVCaptureDevicePosition)position {
    
    __block AVCaptureDevice *newCaptureDevice = nil;//查询到的可用的镜头,
    
    if (@available (iOS 10.2, *)) {
        //iOS10.2版本以后使用AVCaptureDeviceDiscoverySession来查询可用的AVCaptureDevice
        //设备类型:广角镜头,双镜头
        NSArray<AVCaptureDeviceType> *deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera];
        
        //AVCaptureDeviceDiscoverySession来查询可用的AVCaptureDevice
        AVCaptureDeviceDiscoverySession *sessionDiscovery = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:position];
        
        //得到当前可用的AVCaptureDevice集合
        NSArray<AVCaptureDevice *> *captureDevices = sessionDiscovery.devices;
        
        //遍历当前可用的AVCaptureDevice,从中找到后置双镜头
        [captureDevices enumerateObjectsUsingBlock:^(AVCaptureDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.position == position && [obj.deviceType isEqualToString:AVCaptureDeviceTypeBuiltInDualCamera]) {
                newCaptureDevice = obj;
                *stop = YES;
            }
        }];
        
        //如果获取后置双镜头失败了,则获取广角镜头
        if (!newCaptureDevice) {
            [captureDevices enumerateObjectsUsingBlock:^(AVCaptureDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.position == position) {
                    newCaptureDevice = obj;
                    *stop = YES;
                }
            }];
        }
        
    } else {
        //获取mediaType类型为AVMediaTypeVideo的AVCaptureDevice,一般就是两个[Back Camera]和[Front Camera]
        NSArray<AVCaptureDevice *> *captureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        //遍历所有可用的AVCaptureDevice，获取后置镜头
        [captureDevices enumerateObjectsUsingBlock:^(AVCaptureDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.position == position) {
                newCaptureDevice = obj;
                *stop = YES;//跳出循环
            }
        }];
    }
    
    return newCaptureDevice;
}

- (void)timeRunning {
    if (self.recordTimeLength < MaxVideoRecordTime) {
        self.recordTimeLength+=TimerRefreshFrequency;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(updateProgress:)]) {
            [self.delegate updateProgress:self.recordTimeLength/MaxVideoRecordTime];
        }
        
        if (MaxVideoRecordTime - self.recordTimeLength == 0) {//录制完成
            [self stopRecord];
        } else {
            
        }
        
    } else {
        //        [self stopTimeCount];
    }
}

#pragma mark - Public methods
/**
 切换前后置摄像头
 */
- (void)turnCameraInputDevice {
    [self.session stopRunning];
    //1.获得当前摄像头位置position
    AVCaptureDevicePosition position = self.videoInput.device.position;
    //2.切换当前使用的摄像头
    position = position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    //3.创建新的视频输入设备
    AVCaptureDevice *videoDevice = [self getAVCaptureDeviceWithPosition:position];
    //4.根据新的videoDevice创建新的输入源
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    //5.更改session中的配置
    [self.session beginConfiguration];
    [self.session removeInput:self.videoInput];
    if ([self.session canAddInput:newInput]) {
        [self.session addInput:newInput];
    }
    [self.session commitConfiguration];
    self.videoInput = newInput;
    
    [self.session startRunning];
}

/**
 开始录制
 */
- (void)startRecord {
    self.isRecording = YES;
    self.timer.fireDate = [NSDate distantPast];
    
    [self.assetWriterManger startWrite];
    self.assetWriterManger.delegate = self;
}

/**
 结束录制
 */
- (void)stopRecord {
    self.isRecording = NO;
    self.timer.fireDate = [NSDate distantFuture];
    self.recordTimeLength = 0;
    
    [self.assetWriterManger stopWrite];
    [self.session stopRunning];
}

/**
 完成录制
 */
- (void)finishRecord {
    [self.assetWriterManger stopWrite];
    [self.session stopRunning];
    //    self.recordState = FMRecordStateFinish;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool {
        //视频
        if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]) {
            @synchronized(self) {
                if (self.assetWriterManger.writeState == RecordStateRecording) {
                    [self.assetWriterManger appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
                }
                
            }
        } else if (connection == [self.audioOutput connectionWithMediaType:AVMediaTypeAudio]) {//音频
            @synchronized(self) {
                
                if (self.assetWriterManger.writeState == RecordStateRecording) {
                    [self.assetWriterManger appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
                }
                
            }
        }
    }
}

#pragma mark - AVAssetWritterManager
- (void)AVAssetWriterManager:(AVAssetWriterManager *)manager didFinishWritting:(NSURL *)videoUrl {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoRecordDidFinish:andVideoUrl:)]) {
        [self.delegate videoRecordDidFinish:self andVideoUrl:videoUrl];
    }
}

#pragma mark - Getters
- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            [_session setSessionPreset:AVCaptureSessionPresetHigh];
        }
    }
    return _session;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//设置比例铺满全屏
    }
    return _previewLayer;
}

- (dispatch_queue_t)captureQueue {
    if (!_captureQueue) {
        //手动创建串行队列,确保视频帧的捕获始终在一个串行队列中进行的
        _captureQueue = dispatch_queue_create("captureNewFrame", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}

- (NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:TimerRefreshFrequency target:self selector:@selector(timeRunning) userInfo:nil repeats:YES];
    }
    return _timer;
}

@end
