//
//  LFVideoView.h
//  LFRecordVideo
//
//  Created by 刘峰 on 2019/1/31.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^DismissBlock)(void);
typedef void(^FinishBlock)(NSURL *videoUrl);

@interface LFVideoView : UIView

@property (nonatomic, copy) DismissBlock dismissBlock;
@property (nonatomic, copy) FinishBlock finishBlock;

@end

NS_ASSUME_NONNULL_END
