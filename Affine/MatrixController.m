/*
Created by Rob Mayoff on 7/29/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "MatrixController.h"
#import "Model.h"

@interface MatrixController () <ModelObserver>
@end

@implementation MatrixController {
    IBOutlet Model *model_;
    IBOutlet UILabel *aLabel_;
    IBOutlet UILabel *bLabel_;
    IBOutlet UILabel *cLabel_;
    IBOutlet UILabel *dLabel_;
    IBOutlet UILabel *txLabel_;
    IBOutlet UILabel *tyLabel_;
    IBOutlet UILabel *dummy0Label_;
    IBOutlet UILabel *dummy1Label_;
    IBOutlet UILabel *dummy2Label_;
}

static NSString *formattedNumber(CGFloat number) {
    return [NSString stringWithFormat:@"%7.3f", number];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [model_ addModelObserver:self];
    [self model:model_ didChangeInterpolatedTransform:model_.interpolatedTransform];
}

- (void)dealloc {
    [model_ removeModelObserver:self];
}

- (void)model:(Model *)model didChangeInterpolatedTransform:(CGAffineTransform)transform {
    aLabel_.text = formattedNumber(transform.a);
    bLabel_.text = formattedNumber(transform.b);
    cLabel_.text = formattedNumber(transform.c);
    dLabel_.text = formattedNumber(transform.d);
    txLabel_.text = formattedNumber(transform.tx);
    tyLabel_.text = formattedNumber(transform.ty);
}

@end
