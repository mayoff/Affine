/*
Created by Rob Mayoff on 7/28/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "DemoView.h"
#import "LocatorView.h"
#import "Model.h"
#import "UIView+translate.h"

@interface DemoView () <ModelObserver>
@end

@implementation DemoView {
    IBOutlet Model *model_;
    IBOutlet LocatorView *originLocator_;
    IBOutlet LocatorView *uLocator_;
    IBOutlet LocatorView *vLocator_;
    CGAffineTransform _uiTransform;
}

#pragma mark - Public API

- (void)awakeFromNib {
    [super awakeFromNib];
    [model_ addModelObserver:self];
}

- (void)dealloc {
    [model_ removeModelObserver:self];
}

- (void)setImageFill:(ImageFillOption)imageFill {
    if (imageFill != _imageFill) {
        _imageFill = imageFill;
        [self setNeedsDisplay];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateUITransform];
    [self layoutLocators];
}

- (void)drawRect:(CGRect)rect {
    [self updateCTM];
    [self fillWithImage];
}

#pragma mark - ModelObserver protocol

- (void)model:(Model *)model didChangeInterpolatedTransform:(CGAffineTransform)transform {
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

#pragma mark - Implementation details

- (CGAffineTransform)transformFromLocators {
    CGAffineTransform inverseUITransform = CGAffineTransformInvert(_uiTransform);
    CGAffineTransform t;
    CGPoint origin = CGPointApplyAffineTransform(originLocator_.center, inverseUITransform);
    t.tx = origin.x;
    t.ty = origin.y;

    CGPoint u = CGPointApplyAffineTransform(uLocator_.center, inverseUITransform);
    t.a = u.x - origin.x;
    t.b = u.y - origin.y;

    CGPoint v = CGPointApplyAffineTransform(vLocator_.center, inverseUITransform);
    t.c = v.x - origin.x;
    t.d = v.y - origin.y;

    return t;
}

- (void)layoutLocators {
    CGAffineTransform t = model_.interpolatedTransform;
    originLocator_.center = CGPointApplyAffineTransform(CGPointMake(t.tx, t.ty), _uiTransform);
    uLocator_.center = CGPointApplyAffineTransform(CGPointMake(t.a + t.tx, t.b + t.ty), _uiTransform);
    vLocator_.center = CGPointApplyAffineTransform(CGPointMake(t.c + t.tx, t.d + t.ty), _uiTransform);
}

- (void)updateUITransform {
    static const CGFloat kScale = 128.0f;
    CGRect bounds = self.bounds;
    _uiTransform = CGAffineTransformIdentity;
    _uiTransform = CGAffineTransformTranslate(_uiTransform, CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    _uiTransform = CGAffineTransformScale(_uiTransform, kScale, -kScale);
}

- (void)updateCTM {
    CGContextRef gc = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(gc, _uiTransform);
    CGContextConcatCTM(gc, model_.interpolatedTransform);
}

- (void)fillWithImage {
    switch (self.imageFill) {
        case ImageFillOption_One:
            CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 1, 1), [self image].CGImage);
            break;
        case imageFillOption_Many:
            CGContextDrawTiledImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 1, 1), [self image].CGImage);
            break;
        default:
            break;
    }
}

- (UIImage *)image {
    static UIImage *theImage;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        theImage = [UIImage imageNamed:@"Picture.jpg"];
    });
    return theImage;
}

- (IBAction)pannerDidUpdate:(UIPanGestureRecognizer *)panner {
    switch (panner.state) {
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            [self updateLocatorsWithPanner:panner];
            [model_ setCurrentPresetToTransform:[self transformFromLocators]];
            break;
        default:
            break;
    }
}

- (void)updateLocatorsWithPanner:(UIPanGestureRecognizer *)panner {
    CGPoint translation = [panner translationInView:self];
    [panner setTranslation:CGPointZero inView:self];
    UIView *view = panner.view;
    [view translate:translation];
    if (view == originLocator_) {
        [uLocator_ translate:translation];
        [vLocator_ translate:translation];
    }
}

@end
