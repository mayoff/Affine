/*
Created by Rob Mayoff on 7/28/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "ViewController.h"
#import "Model.h"
#import "DemoView.h"

@class PresetController;
@class MatrixController;

@interface ViewController () <ModelObserver>

@end

@implementation ViewController {
    IBOutlet Model *model_;
    IBOutlet PresetController *preset0Controller_; // required to keep it from being deallocated
    IBOutlet PresetController *preset1Controller_; // required to keep it from being deallocated
    IBOutlet MatrixController *matrixController_; // required to keep it from being deallocated
    IBOutlet DemoView *demoView_;
    IBOutlet UISlider *interpolationSlider_;
    IBOutlet UISwitch *allowShearingSwitch_;
    IBOutlet UISwitch *allowScalingSwitch_;
    IBOutlet UISegmentedControl *imageFillControl_;
    IBOutlet UISegmentedControl *interpolationTypeControl_;
    BOOL updateControlsIsPending_ : 1;
}

#pragma mark - Public API

- (void)viewDidLoad {
    [super viewDidLoad];
    [model_ addModelObserver:self];
    [self updateControlsFromModel];
}

- (void)dealloc {
    [model_ removeModelObserver:self];
}

#pragma mark - ModelObserver protocol

- (void)model:(Model *)model didChangeAllowsScaling:(BOOL)allowsScaling {
    [self updateControlsFromModel];
}

- (void)model:(Model *)model didChangeAllowsShearing:(BOOL)allowsShearing {
    [self updateControlsFromModel];
}

- (void)model:(Model *)model didChangeInterpolationAbscissa:(CGFloat)abscissa {
    [self updateControlsFromModel];
}

#pragma mark - Implementation details

- (IBAction)updateImageFillOptionFromControl {
    demoView_.imageFill = (ImageFillOption)imageFillControl_.selectedSegmentIndex;
}

-  (IBAction)updateModelFromControls {
    model_.allowsShearing = allowShearingSwitch_.on;
    model_.allowsScaling = allowScalingSwitch_.on;
    model_.interpolationAbscissa = interpolationSlider_.value;
    model_.interpolationType = (InterpolationType)interpolationTypeControl_.selectedSegmentIndex;
}

- (void)setControlsNeedUpdating {
    if (updateControlsIsPending_)
        return;
    updateControlsIsPending_ = YES;
    [self performSelectorOnMainThread:@selector(updateControlsFromModel) withObject:nil waitUntilDone:NO];
}

- (void)updateControlsFromModel {
    updateControlsIsPending_ = NO;
    allowScalingSwitch_.on = model_.allowsScaling;
    allowShearingSwitch_.on = model_.allowsShearing;
    interpolationSlider_.value = model_.interpolationAbscissa;
    interpolationTypeControl_.selectedSegmentIndex = model_.interpolationType;
}

- (IBAction)demoViewWasDoubleTapped:(id)sender {
    [model_ setCurrentPresetToTransform:CGAffineTransformIdentity];
}

@end
