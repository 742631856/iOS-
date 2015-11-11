//
//  MyButton.h
//  录音
//
//  Created by min on 15/8/6.
//  Copyright (c) 2015年 mao. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RecorderButtonDelegate <NSObject>

- (void)touchBegan;       //点击开始
- (void)touchEnded;       //点击结束
- (void)touchCancelled;   //点击取消

@end

@interface RecorderButton : UIButton

@property (nonatomic) id<RecorderButtonDelegate> delegate;

@end
