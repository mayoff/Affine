/*
Created by Rob Mayoff on 7/28/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "Model.h"
#import "ObserverSet.h"
#import "PolarVector.h"

@implementation Model {
    ObserverSet *observers_;
    BOOL allowsScalingDidChange_ : 1;
    BOOL allowsShearingDidChange_ : 1;
    BOOL preset0DidChange_ : 1;
    BOOL preset1DidChange_ : 1;
    BOOL interpolationAbscissaDidChange_ : 1;
    BOOL interpolationTypeDidChange_ : 1;
}

#pragma mark - Public API

- (id)init {
    if (!(self = [super init]))
        return nil;

    _preset0 = CGAffineTransformIdentity;
    _preset1 = CGAffineTransformIdentity;
    observers_ = [ObserverSet new];
    observers_.protocol = @protocol(ModelObserver);

    return self;
}

- (void)addModelObserver:(id<ModelObserver>)observer {
    [observers_ addObserverObject:observer];
}

- (void)removeModelObserver:(id<ModelObserver>)observer {
    [observers_ removeObserverObject:observer];
}

- (CGAffineTransform)interpolatedTransform {
    switch (_interpolationType) {
        case InterpolationType_Rectangular:
            return [self rectangularInterpolatedTransform];
        case InterpolationType_Polar:
            return [self polarInterpolatedTransform];
        case InterpolationType_SmartPolar:
            return [self smartPolarInterpolatedTransform];
    }
}

- (void)setAllowsScaling:(BOOL)allowsScaling {
    if (allowsScaling != _allowsScaling) {
        _allowsScaling = allowsScaling;
        allowsScalingDidChange_ = YES;
        [self enforceConstraints];
        [self notifyObservers];
    }
}

- (void)setAllowsShearing:(BOOL)allowsShearing {
    if (allowsShearing != _allowsShearing) {
        _allowsShearing = allowsShearing;
        allowsShearingDidChange_ = YES;
        [self enforceConstraints];
        [self notifyObservers];
    }
}

- (void)setCurrentPresetToTransform:(CGAffineTransform)transform {
    if (_interpolationAbscissa == 0.0f) {
        self.preset0 = transform;
    } else if (_interpolationAbscissa == 1.0f) {
        self.preset1 = transform;
    }
}

- (void)setPreset0:(CGAffineTransform)preset0 {
    [self setPreset0WithoutNotifying:preset0];
    [self notifyObservers];
}

- (void)setPreset1:(CGAffineTransform)preset1 {
    [self setPreset1WithoutNotifying:preset1];
    [self notifyObservers];
}

- (void)setInterpolationAbscissa:(CGFloat)interpolationAbscissa {
    interpolationAbscissa = MAX(0.0f, MIN(interpolationAbscissa, 1.0f));
    if (interpolationAbscissa != _interpolationAbscissa) {
        _interpolationAbscissa = interpolationAbscissa;
        interpolationAbscissaDidChange_ = YES;
        [self notifyObservers];
    }
}

- (void)setInterpolationType:(InterpolationType)interpolationType {
    if (interpolationType != _interpolationType) {
        _interpolationType = interpolationType;
        interpolationTypeDidChange_ = YES;
        [self notifyObservers];
    }
}

#pragma mark - Implementation details

- (void)notifyObservers {
    BOOL interpolatedTransformDidChange = interpolationAbscissaDidChange_ || preset0DidChange_ || preset1DidChange_ || interpolationTypeDidChange_;
    id<ModelObserver> proxy = observers_.proxy;

    if (interpolatedTransformDidChange) {
        [proxy model:self didChangeInterpolatedTransform:self.interpolatedTransform];
    }

    preset0DidChange_ = NO;
    preset1DidChange_ = NO;
    interpolationTypeDidChange_ = NO;
    
    if (allowsScalingDidChange_) {
        allowsScalingDidChange_ = NO;
        [proxy model:self didChangeAllowsScaling:_allowsScaling];
    }

    if (allowsShearingDidChange_) {
        allowsShearingDidChange_ = NO;
        [proxy model:self didChangeAllowsShearing:_allowsShearing];
    }

    if (interpolationAbscissaDidChange_) {
        interpolationAbscissaDidChange_ = NO;
        [proxy model:self didChangeInterpolationAbscissa:_interpolationAbscissa];
    }
}

- (void)enforceConstraints {
    [self setPreset0WithoutNotifying:_preset0];
    [self setPreset1WithoutNotifying:_preset1];
}

- (void)setPreset0WithoutNotifying:(CGAffineTransform)preset0 {
    preset0 = [self constrainedTransformWithTransform:preset0];
    if (!CGAffineTransformEqualToTransform(preset0, _preset0)) {
        _preset0 = preset0;
        preset0DidChange_ = YES;
    }
}

- (void)setPreset1WithoutNotifying:(CGAffineTransform)preset1 {
    preset1 = [self constrainedTransformWithTransform:preset1];
    if (!CGAffineTransformEqualToTransform(preset1, _preset1)) {
        _preset1 = preset1;
        preset1DidChange_ = YES;
    }
}

- (CGAffineTransform)constrainedTransformWithTransform:(CGAffineTransform)transform {
    if (!_allowsScaling) {
        CGFloat h = hypotf(transform.a, transform.b);
        transform.a /= h;
        transform.b /= h;
        if (_allowsShearing) {
            h = hypotf(transform.c, transform.d);
            transform.c /= h;
            transform.d /= h;
        }
    }

    if (!_allowsShearing) {
        transform.c = -transform.b;
        transform.d = transform.a;
    }
    
    return transform;
}

static inline CGPoint interpolateCGPoints(CGFloat t, CGPoint p0, CGPoint p1) {
    CGFloat u = 1.0f - t;
    return CGPointMake(u * p0.x + t * p1.x, u * p0.y + t * p1.y);
}

static inline PolarVector interpolatePolarVectors(CGFloat t, PolarVector v0, PolarVector v1) {
    if (v1.a - v0.a < -M_PI) {
        v1.a += 2 * M_PI;
    } else if (v1.a - v0.a > M_PI) {
        v1.a -= 2 * M_PI;
    }
    CGFloat u = 1.0f - t;
    return (PolarVector){ u * v0.r + t * v1.r, u * v0.a + t * v1.a };
}

static inline CGPoint interpolateCGPointsViaPolar(CGFloat t, CGPoint p0, CGPoint p1) {
    return pointFromPolarVector(interpolatePolarVectors(t, PolarVectorFromCGPoint(p0), PolarVectorFromCGPoint(p1)));
}

- (CGAffineTransform)rectangularInterpolatedTransform {
    CGFloat t = _interpolationAbscissa;
    CGAffineTransform r;
    for (NSUInteger i = 0; i < 3; ++i) {
        ((CGPoint *)&r.a)[i] = interpolateCGPoints(t, ((CGPoint *)&_preset0.a)[i], ((CGPoint *)&_preset1.a)[i]);
    }
    return r;
}

- (CGAffineTransform)polarInterpolatedTransform {
    CGFloat t = _interpolationAbscissa;
    CGAffineTransform middleStorage;
    CGPoint *start = (CGPoint *)&_preset0;
    CGPoint *end = (CGPoint *)&_preset1;
    CGPoint *middle = (CGPoint *)&middleStorage;
    middle[0] = interpolateCGPointsViaPolar(t, start[0], end[0]);
    middle[1] = interpolateCGPointsViaPolar(t, start[1], end[1]);
    middle[2] = interpolateCGPoints(t, start[2], end[2]);
    return middleStorage;
}

static inline CGFloat endAngleToMinimizeRotation(CGFloat startAngle, CGFloat endAngle) {
    // Make the rotation <= M_PI radians.
    return (endAngle - startAngle < -M_PI) ? (endAngle + 2 * M_PI)
        : (endAngle - startAngle > M_PI) ? (endAngle - 2 * M_PI)
        : endAngle;
}

static inline CGFloat addRadians(CGFloat r0, CGFloat r1) {
    CGFloat r = r0 + r1;
    if (r < -M_PI) {
        r += 2 * M_PI;
    } else if (r > M_PI) {
        r -= 2 * M_PI;
    }
    return r;
}

static inline CGPoint addPoints(CGPoint lhs, CGPoint rhs) {
    return CGPointMake(lhs.x + rhs.x, lhs.y + rhs.y);
}

static inline CGPoint subtractPoints(CGPoint lhs, CGPoint rhs) {
    return CGPointMake(lhs.x - rhs.x, lhs.y - rhs.y);
}

static inline PolarVector relativeChord(CGPoint a, CGPoint b) {
    PolarVector reference = PolarVectorFromCGPoint(a);
    PolarVector absoluteChord = PolarVectorFromCGPoint(CGPointMake(b.x - a.x, b.y - a.y));
    return (PolarVector){ absoluteChord.r, addRadians(absoluteChord.a, -reference.a) };
}

- (CGAffineTransform)smartPolarInterpolatedTransform {
    CGFloat t = _interpolationAbscissa;
    PolarAffineTransform start = PolarAffineTransformFromAffineTransform(_preset0);
    PolarAffineTransform end = PolarAffineTransformFromAffineTransform(_preset1);
    PolarAffineTransform middle;

    middle.u = interpolatePolarVectors(t, start.u, end.u);
    middle.v = interpolatePolarVectors(t, start.v, end.v);
    middle.t = interpolateCGPoints(t, start.t, end.t);

    return affineTransformFromPolarAffineTransform(middle);
}

@end
