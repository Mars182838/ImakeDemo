//
//  JYShakeAlterView.m
//  摇一摇
//
//  Created by 俊王 on 16/3/28.
//  Copyright © 2016年 nacker. All rights reserved.
//

#import "JYParameterAlterView.h"
#import "UIColor+Additions.h"

@interface JYParameterAlterView()<UITextFieldDelegate>
{
    NSInteger count;
    CGFloat factorFloat;
    
    CGFloat jWindowWidth;
    CGFloat jWindowHeight;
    CGFloat jTextHeight;
    CGFloat jTitleHeight;
    CGFloat jCircleHeight;
}

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, copy) JYParameterAlterViewBlock alterViewBlock;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, assign) CGSize size;

@property (nonatomic, strong) NSArray *buttonsArray;

@property (nonatomic, strong) UIView *btnBackgroundView;

@property (nonatomic, strong) NSMutableArray *imageArray;

@property (nonatomic, strong) NSArray *textFiledArray;

@property (nonatomic, strong) UIButton *selectedBtn;


@end

@implementation JYParameterAlterView

-(JYParameterAlterView *)init
{
    self = [super init];
    
    if (self) {
        
        self.frame = [UIScreen mainScreen].bounds;
        
        jWindowWidth = self.frame.size.width - 50;
        
        jWindowHeight = 280.0f;
        jTitleHeight = 30;
        jTextHeight = 45.0f;
        jCircleHeight = 30.0f;
        
        _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        _backgroundView.backgroundColor = [UIColor blackColor];
        _backgroundView.alpha = 0.6;
        [self addSubview:_backgroundView];
        
        _contentView = [[UIView alloc] init];
        _contentView.frame = CGRectMake(0.0f, 0, jWindowWidth, jWindowHeight);
        _contentView.backgroundColor = [UIColor whiteColor];
        _contentView.layer.cornerRadius = 10.0f;
        _contentView.layer.masksToBounds = YES;
        [self addSubview:_contentView];
        
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, _contentView.frame.size.width,jTitleHeight)];
        _messageLabel.text = @"参数设置";
        _messageLabel.textColor = [UIColor colorWithHexString:@"57CEF0"];
        _messageLabel.font = [UIFont systemFontOfSize:20];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        [_contentView addSubview:_messageLabel];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, _messageLabel.frame.origin.y + _messageLabel.frame.size.height, _contentView.frame.size.width, 1)];
        lineView.backgroundColor = [UIColor colorWithHexString:@"57CEF0"];
        [_contentView addSubview:lineView];
        
        _contentView.center = _backgroundView.center;
        self.imageArray = [[NSMutableArray alloc] initWithCapacity:0];
        
        _selectedBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _selectedBtn.frame = CGRectMake(40, 220, (jWindowWidth - 3*40)/2, 40);
        [_selectedBtn setTitle:@"确定" forState:UIControlStateNormal];
        [_selectedBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_selectedBtn setBackgroundColor:[UIColor colorWithHexString:@"57CEFO"]];
        _selectedBtn.tag = 10;
        [_selectedBtn addTarget:self action:@selector(dismissBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:_selectedBtn];
        
        
        UIButton *cancleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        cancleBtn.frame = CGRectMake((jWindowWidth - 3*40)/2 + 80, 220, (jWindowWidth - 3*40)/2, 40);
        [cancleBtn setTitle:@"取消" forState:UIControlStateNormal];
        [cancleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        cancleBtn.tag = 11;
        [cancleBtn setBackgroundColor:[UIColor colorWithHexString:@"57CEFO"]];
        [cancleBtn addTarget:self action:@selector(dismissBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:cancleBtn];
        
        self.imageArray = [NSMutableArray new];
    }
    
    return self;
}

-(void)creatView{
    
    NSInteger arrayCount = self.buttonsArray.count;
    
    for (NSInteger i = 0 ; i < arrayCount; i++) {
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, (_messageLabel.frame.origin.y + jTextHeight) + 30*i , 90, 30)];
        label.text = self.buttonsArray[i];
        label.font = [UIFont systemFontOfSize:12];
        [_contentView addSubview:label];
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(label.frame.origin.x + label.frame.size.width + 10, (_messageLabel.frame.origin.y + jTextHeight) + 30*i , jWindowWidth - 130, 30)];
        textField.backgroundColor = [UIColor clearColor];
        textField.delegate = self;
        textField.tag = (10+i);
        [_contentView addSubview:textField];
        [self.imageArray addObject:textField];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(label.frame.origin.x + label.frame.size.width + 10, (_messageLabel.frame.origin.y + jTextHeight) + 30*(i + 1), jWindowWidth - 130, 1)];
        lineView.backgroundColor = [UIColor colorWithHexString:@"57CEF0"];
        [_contentView addSubview:lineView];
    }
}

-(void)updateUI{
    
    self.textFiledArray = @[self.parameterObject.minPiston,self.parameterObject.maxPiston,self.parameterObject.minMotor,self.parameterObject.maxMotor,self.parameterObject.threshold];
    
    for (NSInteger i = 0; i < self.textFiledArray.count; i++) {
        
        UITextField *textField = (UITextField *)self.imageArray[i];
        textField.text = self.textFiledArray[i];
    }
}

-(instancetype)initwithTypeArray:(NSArray *)array dismissBlock:(JYParameterAlterViewBlock)dismissBlock
{
    if ([self init]) {
        
        self.alterViewBlock = dismissBlock;
        self.buttonsArray = array;
        
        [self creatView];

    }
    
    return self;
}

-(void)show
{
    [self updateUI];
    
    POPBasicAnimation *offscreenAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    offscreenAnimation.fromValue = @(-1*self.frame.size.height);
    [offscreenAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        
    }];
    
    POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    positionAnimation.toValue = @(self.center.y);
    positionAnimation.springBounciness = 10;
    [positionAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        
    }];
    
    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.springBounciness = 10;
    scaleAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(1.6, 1.8)];
    
    [self.contentView.layer pop_addAnimation:offscreenAnimation forKey:@"offscreenAnimation"];
    [self.contentView.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
    [self.contentView.layer pop_addAnimation:positionAnimation forKey:@"positionAnimation"];

    [[[UIApplication sharedApplication] keyWindow] addSubview:self];
}

-(void)dismissBtn:(UIButton *)sender{
    
    self.alterViewBlock(sender.tag);

    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.springBounciness = 10;
    scaleAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(0.6, 0.8)];
    
    POPBasicAnimation *offscreenAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    offscreenAnimation.toValue = @(1.5*self.frame.size.height);
    [offscreenAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        
        [self removeFromSuperview];
        
    }];
    
    [self.contentView.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
    [self.contentView.layer pop_addAnimation:offscreenAnimation forKey:@"offscreenAnimation"];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self endEditing:YES];
    
    self.contentView.transform = CGAffineTransformIdentity;

}

#pragma mark
#pragma mark UITextFiledDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.contentView.transform = CGAffineTransformMakeTranslation(0, -120);
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    switch (textField.tag) {
        case 10:{
            
            self.parameterObject.minPiston = textField.text;
            
            break;
        }
        case 11:{
            
            self.parameterObject.maxPiston = textField.text;

            break;
        }
        case 12:{
            
            self.parameterObject.minMotor = textField.text;

            break;
        }
        case 13:{
            
            self.parameterObject.maxMotor = textField.text;

            break;
        }
        case 14:{
            
            self.parameterObject.threshold = textField.text;

            break;
        }
        default:
            break;
    }
}


@end


