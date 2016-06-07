//
//  JYShakeAlterView.h
//  摇一摇
//
//  Created by 俊王 on 16/3/28.
//  Copyright © 2016年 nacker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <pop/POP.h>
#import "JYParameterObject.h"

typedef void (^JYParameterAlterViewBlock)(NSInteger count);

@interface JYParameterAlterView : UIView

@property (nonatomic, strong) JYParameterObject *parameterObject;

@property (nonatomic, strong) UILabel *messageLabel;

-(void)updateUI;

-(instancetype)initwithTypeArray:(NSArray *)array
                     dismissBlock:(JYParameterAlterViewBlock )dismissBlock;

-(void)show;

@end
