/*
Created by Rob Mayoff on 7/28/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "DemoView.h"
#import "LocatorView.h"
#import "Model.h"
#import "UIView+translate.h"

static const CGFloat kScale = 128.0f;

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
    CGContextConcatCTM(UIGraphicsGetCurrentContext(), _uiTransform);
    [self fillWithImage];
    [self drawUntransformedGrid];
    [self drawVectors];
}

#pragma mark - ModelObserver protocol

- (void)model:(Model *)model didChangeInterpolatedTransform:(CGAffineTransform)transform {
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

#pragma mark - Layout details

- (void)layoutLocators {
    CGAffineTransform t = model_.interpolatedTransform;
    originLocator_.center = CGPointApplyAffineTransform(CGPointMake(t.tx, t.ty), _uiTransform);
    uLocator_.center = CGPointApplyAffineTransform(CGPointMake(t.a + t.tx, t.b + t.ty), _uiTransform);
    vLocator_.center = CGPointApplyAffineTransform(CGPointMake(t.c + t.tx, t.d + t.ty), _uiTransform);
}

- (void)updateUITransform {
    CGRect bounds = self.bounds;
    _uiTransform = CGAffineTransformIdentity;
    _uiTransform = CGAffineTransformTranslate(_uiTransform, CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    _uiTransform = CGAffineTransformScale(_uiTransform, kScale, -kScale);
}

#pragma mark - Drawing details

- (void)updateCTM {
    CGContextRef gc = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(gc, model_.interpolatedTransform);
}

- (void)fillWithImage {
    if (_imageFill == ImageFillOption_None)
        return;
    
    CGContextRef gc = UIGraphicsGetCurrentContext();
    CGContextSaveGState(gc); {
        CGContextConcatCTM(gc, model_.interpolatedTransform);
        switch (_imageFill) {
            case ImageFillOption_One:
                CGContextDrawImage(gc, CGRectMake(0, 0, 1, 1), [self image].CGImage);
                break;
            case imageFillOption_Many:
                CGContextDrawTiledImage(gc, CGRectMake(0, 0, 1, 1), [self image].CGImage);
                break;
            default:
                break;
        }
    } CGContextRestoreGState(gc);
}

- (UIImage *)image {
    static UIImage *theImage;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        theImage = [UIImage imageNamed:@"Picture.jpg"];
    });
    return theImage;
}

- (void)drawUntransformedGrid {
    CGContextRef gc = UIGraphicsGetCurrentContext();
    CGRect bounds = CGRectIntegral(CGContextGetClipBoundingBox(gc));
    [[UIColor blackColor] setFill];
    for (CGFloat y = CGRectGetMinY(bounds), yMax = CGRectGetMaxY(bounds); y < yMax; y += 1.0f) {
        UIRectFill(CGRectMake(bounds.origin.x, y, bounds.size.width, 1.0f / kScale));
    }
    for (CGFloat x = CGRectGetMinX(bounds), xMax = CGRectGetMaxX(bounds); x < xMax; x += 1.0f) {
        UIRectFill(CGRectMake(x, bounds.origin.y, 1.0f / kScale, bounds.size.height));
    }
}

- (void)drawVectors {
    CGContextRef gc = UIGraphicsGetCurrentContext();
    CGAffineTransform t = model_.interpolatedTransform;
    [[UIColor blackColor] set];
    CGContextSetLineCap(gc, kCGLineCapSquare);
    CGContextSetLineJoin(gc, kCGLineJoinMiter);
    CGPoint origin = CGPointMake(t.tx, t.ty);
    [self drawVector:origin startingAtPoint:CGPointZero];
    [self drawVector:CGPointMake(t.a, t.b) startingAtPoint:origin];
    [self drawVector:CGPointMake(t.c, t.d) startingAtPoint:origin];
}

- (void)drawVector:(CGPoint)vector startingAtPoint:(CGPoint)start {
    CGFloat scale = hypotf(vector.x, vector.y);
    static const CGFloat kArrowHeadLength = 0.15f;
    if (scale < kArrowHeadLength)
        return;
    CGFloat x = 1.0f - kArrowHeadLength / scale;
    CGFloat y = 0.05f / scale;

    CGContextRef gc = UIGraphicsGetCurrentContext();
    CGContextSaveGState(gc); {
        CGContextTranslateCTM(gc, start.x, start.y);
        CGContextRotateCTM(gc, atan2f(vector.y, vector.x));
        CGContextScaleCTM(gc, scale, scale);

        CGContextSetLineWidth(gc, 3.0 / kScale / scale);
        CGContextBeginPath(gc);
        CGContextMoveToPoint(gc, 0, 0);
        CGContextAddLineToPoint(gc, x, 0);
        CGContextStrokePath(gc);

        CGContextBeginPath(gc);
        CGContextMoveToPoint(gc, 1, 0);
        CGContextAddLineToPoint(gc, x, y);
        CGContextAddLineToPoint(gc, x, -y);
        CGContextClosePath(gc);
        CGContextFillPath(gc);

    } CGContextRestoreGState(gc);
}

#pragma mark - Locator dragging details

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
