/*
Created by Rob Mayoff on 7/28/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import <UIKit/UIKit.h>

@class LocatorView;

typedef enum {
    ImageFillOption_None,
    ImageFillOption_One,
    imageFillOption_Many
} ImageFillOption;

@interface DemoView : UIView

@property (nonatomic) ImageFillOption imageFill;
@property (nonatomic, readonly) CGAffineTransform uiTransform;

@end

