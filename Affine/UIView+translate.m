/*
Created by Rob Mayoff on 7/28/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "UIView+translate.h"

@implementation UIView (translate)

- (void)translate:(CGPoint)translation {
    CGPoint center = self.center;
    center.x += translation.x;
    center.y += translation.y;
    self.center = center;
}

@end
