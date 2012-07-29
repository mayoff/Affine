/*
Created by Rob Mayoff on 7/28/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "LocatorView.h"
#import "Model.h"

@implementation LocatorView {
    BOOL updateAlphaIsPending_ : 1;
    IBOutlet Model *model_;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [model_ addModelObserver:self];
    [self setNeedsAlphaUpdate];
}

- (void)dealloc {
    [model_ removeModelObserver:self];
}

- (void)setNeedsAlphaUpdate {
    if (updateAlphaIsPending_)
        return;
    updateAlphaIsPending_ = YES;
    [self performSelectorOnMainThread:@selector(updateAlpha) withObject:nil waitUntilDone:NO];
}

- (BOOL)shouldHideAccordingToModel:(Model *)model {
    CGFloat abscissa = model.interpolationAbscissa;
    return abscissa != 0.0f && abscissa != 1.0f;
}

- (void)model:(Model *)model didChangeInterpolationAbscissa:(CGFloat)abscissa {
    [self setNeedsAlphaUpdate];
}

- (void)updateAlpha {
    updateAlphaIsPending_ = NO;
    self.alpha = [self shouldHideAccordingToModel:model_] ? 0.0f : 1.0f;
}

- (void)setAlpha:(CGFloat)alpha {
    if (alpha == self.alpha)
        return;
    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState animations:^{
        [super setAlpha:alpha];
    } completion:nil];
}

@end
