//
//  LFVideoProgressLayer.h
//  LFRecordVideo
//
//  Created by 刘峰 on 2019/2/8.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface LFVideoProgressLayer : CALayer

@property (nonatomic, assign) CGFloat progress;

- (instancetype)initWithProgressFrame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
