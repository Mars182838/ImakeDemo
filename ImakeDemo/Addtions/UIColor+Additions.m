//
//  UIColor+Additions.m
//  YuanGongBao
//
//  Created by Mars on 14-9-15.
//  Copyright (c) 2014年 YiJie. All rights reserved.
//

#import "UIColor+Additions.h"

@implementation UIColor (Additions)

+ (UIColor *)colorWithHex:(NSUInteger)hex
{
    NSUInteger a = (hex >> 24) & 0xFF;
    NSUInteger r = (hex >> 16) & 0xFF;
    NSUInteger g = (hex >> 8 ) & 0xFF;
    NSUInteger b = hex & 0xFF;
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a / 255.0f];
}

+ (UIColor *)colorWithHexString:(NSString *)hexString
{
    if ([hexString hasPrefix:@"#"])
    {
        hexString=[hexString substringFromIndex:1];
    }
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    unsigned long long colorValue = 0;
    [scanner scanHexLongLong:&colorValue];
    unsigned long long redValue = (colorValue & 0xFF0000) >> 16;
    unsigned long long greenValue = (colorValue & 0xFF00) >> 8;
    unsigned long long blueValue = colorValue & 0xFF;
    return [UIColor colorWithRed:redValue/255.0 green:greenValue/255.0 blue:blueValue/255.0 alpha:1];
}

+ (UIColor *)colorWithHex:(uint) hex alpha:(CGFloat)alpha{
    int red, green, blue;
    blue = hex & 0x0000FF;
    green = ((hex & 0x00FF00) >> 8);
    red = ((hex & 0xFF0000) >> 16);
    return [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:alpha];
}

+ (UIColor *)colorWithIntegerRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(CGFloat)alpha
{
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha];
}

+ (UIColor *)themeColor
{
    return [UIColor colorWithIntegerRed:240 green:81 blue:65 alpha:1];
}
+(UIColor *) randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 ); //0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0,away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5; //0.5 to 1.0,away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

//标题
+ (UIColor *)themeTitleColor
{
    return [UIColor colorWithHex:0xFF3B3B3B];
}

@end
