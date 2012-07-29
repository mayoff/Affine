/*
Created by Rob Mayoff on 7/29/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "ShearLocatorView.h"

@implementation ShearLocatorView

- (void)model:(Model *)model didChangeAllowsShearing:(BOOL)allowsShearing {
    [self setNeedsAlphaUpdate];
}

- (BOOL)shouldHideAccordingToModel:(Model *)model {
    return !model.allowsShearing || [super shouldHideAccordingToModel:model];
}

@end
