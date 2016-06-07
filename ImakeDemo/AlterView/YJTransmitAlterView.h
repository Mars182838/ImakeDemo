//
//  YJTransmitAlterView.h
//  ImakeDemo
//
//  Created by 俊王 on 16/4/15.
//  Copyright © 2016年 EB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <pop/POP.h>

typedef void (^YJTransmitAlterViewBlock)(NSInteger count, NSInteger index, NSString *textString);

@interface YJTransmitAlterView : UIView

@property (nonatomic, strong) UILabel *messageLabel;

-(instancetype)initwithTypeArray:(NSArray *)array
                    dismissBlock:(YJTransmitAlterViewBlock )dismissBlock;

-(void)show;

@end

