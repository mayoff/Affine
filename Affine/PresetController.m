/*
Created by Rob Mayoff on 7/28/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "PresetController.h"
#import "Model.h"

@interface PresetController () <ModelObserver>
@end

@implementation PresetController {
    IBOutlet Model *model_;
    IBOutlet UIButton *button_;
    BOOL selected_ : 1;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [model_ addModelObserver:self];
    [self model:model_ didChangeInterpolationAbscissa:model_.interpolationAbscissa];

    CALayer *layer = button_.layer;
    layer.shadowColor = [UIColor blueColor].CGColor;
    layer.shadowRadius = 5;
    layer.shadowOffset = CGSizeZero;
}

- (void)dealloc {
    [model_ removeModelObserver:self];
}

- (IBAction)selectPreset {
    model_.interpolationAbscissa = self.interpolationValue;
}

- (void)model:(Model *)model didChangeInterpolationAbscissa:(CGFloat)abscissa {
    BOOL selected = abscissa == self.interpolationValue;
    if (selected == selected_)
        return;
    selected_ = selected;
    button_.selected = selected;
    CALayer *layer = button_.layer;
    if (selected) {
        layer .shadowOpacity = 1;
    } else {
        layer.shadowOpacity = 0;
    }
}

@end
