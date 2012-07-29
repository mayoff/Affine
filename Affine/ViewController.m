/*
Created by Rob Mayoff on 7/28/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "ViewController.h"
#import "DemoView.h"
#import "AffinePresetController.h"

@interface ViewController () <DemoViewDelegate>

@end

@implementation ViewController {
    IBOutlet AffinePresetController *aPreset_;
    IBOutlet AffinePresetController *bPreset_;
    AffinePresetController *selectedPreset_;
    IBOutlet UISlider *interpolationSlider_;
    IBOutlet DemoView *affineView_;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    selectedPreset_ = aPreset_;
    [self updateControlState];
}

- (IBAction)aButtonWasTapped {
    selectedPreset_ = aPreset_;
    [self updateControlState];
}

- (IBAction)bButtonWasTapped {
    selectedPreset_ = bPreset_;
    [self updateControlState];
}

- (IBAction)interpolationSliderValueDidChange {
    CGFloat value = interpolationSlider_.value;
    if (value == aPreset_.interpolationValue) {
        selectedPreset_ = aPreset_;
    } else if (value == bPreset_.interpolationValue) {
        selectedPreset_ = bPreset_;
    } else {
        selectedPreset_ = nil;
    }
    [self updateControlState];
}

- (void)updateControlState {
    [aPreset_ setSelectedIfEqualToPreset:selectedPreset_];
    [bPreset_ setSelectedIfEqualToPreset:selectedPreset_];
    if (selectedPreset_) {
        interpolationSlider_.value = selectedPreset_.interpolationValue;
    }
    affineView_.demoTransform = [self interpolatedTransform];
    affineView_.editable = selectedPreset_ != nil;
}

- (void)demoView:(DemoView *)view didChangeDemoTransform:(CGAffineTransform)transform {
    selectedPreset_.transform = transform;
}

- (CGAffineTransform)interpolatedTransform {
    CGFloat t = interpolationSlider_.value;
    CGFloat u = 1.0f - t;
    CGAffineTransform a = aPreset_.transform;
    CGAffineTransform b = bPreset_.transform;
    CGAffineTransform r;
#define Interpolate(Element) r.Element = u * a.Element + t * b.Element
    Interpolate(a);
    Interpolate(b);
    Interpolate(c);
    Interpolate(d);
    Interpolate(tx);
    Interpolate(ty);
#undef Interpolate
    return r;
}

@end
