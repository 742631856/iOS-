//
//  MyButton.m
//  录音
//
//  Created by min on 15/8/6.
//  Copyright (c) 2015年 mao. All rights reserved.
//

#import "RecorderButton.h"

@implementation RecorderButton

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"开始");
    [super touchesBegan:touches withEvent:event];
    
    if ([_delegate respondsToSelector:@selector(touchBegan)]) {
        [_delegate touchBegan];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"结束");
    [super touchesEnded:touches withEvent:event];
    if ([_delegate respondsToSelector:@selector(touchEnded)]) {
        [_delegate touchEnded];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"取消");
    [super touchesCancelled:touches withEvent:event];
    if ([_delegate respondsToSelector:@selector(touchCancelled)]) {
        [_delegate touchCancelled];
    }
}

@end
