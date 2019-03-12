//
//  LFVideoProgressLayer.m
//  LFRecordVideo
//
//  Created by 刘峰 on 2019/2/8.
//  Copyright © 2019年 Liufeng. All rights reserved.
//

#import "LFVideoProgressLayer.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface LFVideoProgressLayer ()

@property (nonatomic, strong) CAShapeLayer *circleShapeLayer;//外侧圆圈
@property (nonatomic, strong) CAShapeLayer *whiteShapeLayer;//内侧白色实心圆
@property (nonatomic, strong) CAShapeLayer *grayShapeLayer;//外侧灰色实心圆

@end

@implementation LFVideoProgressLayer

- (instancetype)initWithProgressFrame:(CGRect)frame {
    if (self = [super init]) {
        self.frame = frame;
        [self setUp];
    }
    return self;
}

- (void)setUp {
    [self addSublayer:self.grayShapeLayer];
    [self addSublayer:self.whiteShapeLayer];
    [self addSublayer:self.circleShapeLayer];
}

- (UIBezierPath *)makeInitCirclePathWithRadius:(CGFloat)radius {
    CGPoint center = CGPointMake(CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame)/2);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:0 endAngle: M_PI * 2 clockwise:YES];
    return path;
}

- (UIBezierPath *)makeProgressPathWithProgress:(CGFloat)progress {
    CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    CGFloat radius = CGRectGetWidth(self.frame)/2;//半径
    CGFloat startAngle = -M_PI_2;
    CGFloat endAngle = -M_PI_2 + M_PI * 2 * progress;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    return path;
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    self.circleShapeLayer.path = [self makeProgressPathWithProgress:progress].CGPath;
    
    self.whiteShapeLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(0.5, 0.5));//28->14半径
    self.whiteShapeLayer.position = CGPointMake(18, 18);
    [self setNeedsDisplay];
//    self.whiteShapeLayer.path = [self makeInitCirclePathWithRadius:CGRectGetWidth(self.frame)/4].CGPath;
//    self.grayShapeLayer.path = [self makeInitCirclePathWithRadius:CGRectGetWidth(self.frame)/2].CGPath;
}

#pragma mark - Getters
- (CAShapeLayer *)circleShapeLayer {
    if (!_circleShapeLayer) {
        _circleShapeLayer = [[CAShapeLayer alloc] init];
        _circleShapeLayer.strokeColor = [UIColor orangeColor].CGColor;
        _circleShapeLayer.fillColor = [UIColor clearColor].CGColor;
        _circleShapeLayer.lineWidth = 5;
        _circleShapeLayer.path = [self makeProgressPathWithProgress:.0f].CGPath;
    }
    return _circleShapeLayer;
}

- (CAShapeLayer *)whiteShapeLayer {
    if (!_whiteShapeLayer) {
        _whiteShapeLayer = [[CAShapeLayer alloc] init];
        _whiteShapeLayer.fillColor = [UIColor whiteColor].CGColor;
        
        _whiteShapeLayer.path = [self makeInitCirclePathWithRadius:CGRectGetWidth(self.frame)/2.5].CGPath;
    }
    return _whiteShapeLayer;
}

- (CAShapeLayer *)grayShapeLayer {
    if (!_grayShapeLayer) {
        _grayShapeLayer = [[CAShapeLayer alloc] init];
        _grayShapeLayer.fillColor = [[UIColor colorWithRed:227.f/255 green:227.f/255 blue:227.f/255 alpha:1.0] CGColor];
        _grayShapeLayer.strokeColor = [[UIColor colorWithRed:227.f/255 green:227.f/255 blue:227.f/255 alpha:1.0] CGColor];
        _grayShapeLayer.lineCap = kCALineCapRound;
        _grayShapeLayer.lineWidth = 5;
        
        _grayShapeLayer.path = [self makeInitCirclePathWithRadius:CGRectGetWidth(self.frame)/2].CGPath;
    }
    return _grayShapeLayer;
}

@end
