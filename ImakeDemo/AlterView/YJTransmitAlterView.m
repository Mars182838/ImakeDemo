//
//  JYShakeAlterView.m
//  摇一摇
//
//  Created by 俊王 on 16/3/28.
//  Copyright © 2016年 nacker. All rights reserved.
//

#import "YJTransmitAlterView.h"
#import "UIColor+Additions.h"

@interface YJTransmitAlterView()<UITextFieldDelegate>
{
    NSInteger count;
    CGFloat factorFloat;
    
    CGFloat jWindowWidth;
    CGFloat jWindowHeight;
    CGFloat jTextHeight;
    CGFloat jTitleHeight;
    CGFloat jCircleHeight;
    
    NSInteger selectedIndex;
}

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, copy) YJTransmitAlterViewBlock alterViewBlock;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, assign) CGSize size;

@property (nonatomic, strong) NSArray *buttonsArray;

@property (nonatomic, strong) UIView *btnBackgroundView;

@property (nonatomic, strong) NSMutableArray *imageArray;

@property (nonatomic, strong) NSArray *textFiledArray;

@property (nonatomic, strong) UIButton *selectedBtn;

@property (nonatomic, strong) NSString *textFieldString;

@end

@implementation YJTransmitAlterView

-(YJTransmitAlterView *)init
{
    self = [super init];
    
    if (self) {
        
        self.frame = [UIScreen mainScreen].bounds;
        
        jWindowWidth = self.frame.size.width - 100;
        
        jWindowHeight = 235.0f;
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
        _messageLabel.text = @"发送蓝牙命令";
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
        _selectedBtn.frame = CGRectMake(40, 180, (jWindowWidth - 3*40)/2, 35);
        [_selectedBtn setTitle:@"确定" forState:UIControlStateNormal];
        [_selectedBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_selectedBtn setBackgroundColor:[UIColor colorWithHexString:@"57CEFO"]];
        _selectedBtn.tag = 10000;
        [_selectedBtn addTarget:self action:@selector(dismissBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:_selectedBtn];
        
        
        UIButton *cancleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        cancleBtn.frame = CGRectMake((jWindowWidth - 3*40)/2 + 80, 180, (jWindowWidth - 3*40)/2, 35);
        [cancleBtn setTitle:@"取消" forState:UIControlStateNormal];
        [cancleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        cancleBtn.tag = 10001;
        [cancleBtn setBackgroundColor:[UIColor colorWithHexString:@"57CEFO"]];
        [cancleBtn addTarget:self action:@selector(dismissBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:cancleBtn];
        
        self.imageArray = [NSMutableArray new];
        
        selectedIndex = 0;
    }
    
    return self;
}

-(void)creatView{
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(30, _messageLabel.frame.origin.y + _messageLabel.frame.size.height+ 20, jWindowWidth - 60, 30)];
    textField.backgroundColor = [UIColor clearColor];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.delegate = self;
    [_contentView addSubview:textField];
    [self.imageArray addObject:textField];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(textField.frame.origin.x, textField.frame.origin.y + textField.frame.size.height + 10, jWindowWidth - 40, 30)];
    label.text = @"16进制，参考：00 00 00 00";
    label.font = [UIFont systemFontOfSize:12];
    [_contentView addSubview:label];
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"char1",@"char6"]];
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.frame = CGRectMake(30, label.frame.origin.y + label.frame.size.height, jWindowWidth - 60, 30);
    [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];  //添加委托方法

    [_contentView addSubview:segmentedControl];
}

-(void)segmentAction:(UISegmentedControl *)seg{

    NSInteger index = seg.selectedSegmentIndex;
    selectedIndex = index;
}

-(instancetype)initwithTypeArray:(NSArray *)array dismissBlock:(YJTransmitAlterViewBlock)dismissBlock
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
    POPBasicAnimation *offscreenAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    offscreenAnimation.fromValue = @(-1.5*self.frame.size.height);
    [offscreenAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        
    }];
    
    POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
    positionAnimation.toValue = @(self.center.y);
    positionAnimation.springBounciness = 20;
    [positionAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        
    }];
    
    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.springBounciness = 20;
    scaleAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(1.6, 1.8)];
    
    [self.contentView.layer pop_addAnimation:positionAnimation forKey:@"positionAnimation"];
    [self.contentView.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
    [self.contentView.layer pop_addAnimation:offscreenAnimation forKey:@"offscreenAnimation"];
    
    [[[UIApplication sharedApplication] keyWindow] addSubview:self];
}

-(void)dismissBtn:(UIButton *)sender{
    
    self.alterViewBlock(sender.tag,selectedIndex,self.textFieldString);
    
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

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.contentView.transform = CGAffineTransformMakeTranslation(0, -60);
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"%@",textField.text);
    
    self.textFieldString = textField.text;
}

@end


