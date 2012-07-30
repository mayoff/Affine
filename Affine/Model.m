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
    CGFloat u = 1.0f - t;
    return (PolarVector){ u * v0.r + t * v1.r, u * v0.a + t * v1.a };
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
    CGAffineTransform r;
    CGPoint *p0 = (CGPoint *)&_preset0;
    CGPoint *p1 = (CGPoint *)&_preset1;
    CGPoint *rp = (CGPoint *)&r;
    rp[0] = pointFromPolarVector(interpolatePolarVectors(t, PolarVectorFromCGPoint(p0[0]), PolarVectorFromCGPoint(p1[0])));
    rp[1] = pointFromPolarVector(interpolatePolarVectors(t, PolarVectorFromCGPoint(p0[1]), PolarVectorFromCGPoint(p1[1])));
    rp[2] = interpolateCGPoints(t, p0[2], p1[2]);
    return r;
}

static inline CGFloat endAngleToMinimizeRotation(CGFloat startAngle, CGFloat endAngle) {
    // Make the rotation <= M_PI radians.
    return (endAngle - startAngle < -M_PI) ? (endAngle + 2 * M_PI)
        : (endAngle - startAngle > M_PI) ? (endAngle - 2 * M_PI)
        : endAngle;
}

static inline BOOL signsAreDifferent(CGFloat a, CGFloat b) {
    return a * b < 0;
}

- (CGAffineTransform)smartPolarInterpolatedTransform {
    CGFloat t = _interpolationAbscissa;
    CGAffineTransform r;
    CGPoint *p0 = (CGPoint *)&_preset0;
    CGPoint *p1 = (CGPoint *)&_preset1;
    CGPoint *rp = (CGPoint *)&r;
    
    rp[0] = pointFromPolarVector(interpolatePolarVectors(t, PolarVectorFromCGPoint(p0[0]), PolarVectorFromCGPoint(p1[0])));

    PolarVector chord0 = PolarVectorFromCGPoint(CGPointMake(p0[1].x - p0[0].x, p0[1].y - p0[0].y));
    PolarVector chord1 = PolarVectorFromCGPoint(CGPointMake(p1[1].x - p1[0].x, p1[1].y - p1[0].y));
    chord1.a = endAngleToMinimizeRotation(chord0.a, chord1.a);
    PolarVector chord = interpolatePolarVectors(t, chord0, chord1);
    CGPoint chordPoint = pointFromPolarVector(chord);
    rp[1].x = rp[0].x + chordPoint.x;
    rp[1].y = rp[0].y + chordPoint.y;

    rp[2] = interpolateCGPoints(t, p0[2], p1[2]);
    return r;
}

@end
