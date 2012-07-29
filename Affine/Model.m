/*
Created by Rob Mayoff on 7/28/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "Model.h"

@implementation Model {
    NSCountedSet *observers_;
    BOOL allowsScalingDidChange_ : 1;
    BOOL allowsShearingDidChange_ : 1;
    BOOL preset0DidChange_ : 1;
    BOOL preset1DidChange_ : 1;
    BOOL interpolationAbscissaDidChange_ : 1;
}

#pragma mark - Public API

- (id)init {
    if (!(self = [super init]))
        return nil;

    _preset0 = CGAffineTransformIdentity;
    _preset1 = CGAffineTransformIdentity;
    observers_ = [NSCountedSet set];

    return self;
}

- (void)addModelObserver:(id<ModelObserver>)observer {
    [observers_ addObject:[NSValue valueWithNonretainedObject:observer]];
}

- (void)removeModelObserver:(id<ModelObserver>)observer {
    [observers_ removeObject:[NSValue valueWithNonretainedObject:observer]];
}

- (CGAffineTransform)interpolatedTransform {
    CGFloat t = _interpolationAbscissa;
    CGFloat u = 1.0f - t;
    CGAffineTransform a = _preset0;
    CGAffineTransform b = _preset1;
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

#pragma mark - Implementation details

- (void)forEachObserverRespondingToSelector:(SEL)selector do:(void (^)(id<ModelObserver> observer))block {
    for (NSValue *value in observers_) {
        id<ModelObserver> observer = [value nonretainedObjectValue];
        if ([observer respondsToSelector:selector]) {
            block(observer);
        }
    }
}

- (void)notifyObservers {
    BOOL interpolatedTransformDidChange = interpolationAbscissaDidChange_ || preset0DidChange_ || preset1DidChange_;
    if (interpolatedTransformDidChange) {
        CGAffineTransform transform = [self interpolatedTransform];
        [self forEachObserverRespondingToSelector:@selector(model:didChangeInterpolatedTransform:) do:^(id<ModelObserver> observer) {
            [observer model:self didChangeInterpolatedTransform:transform];
        }];
    }

    preset0DidChange_ = NO;
    preset1DidChange_ = NO;
    
    if (allowsScalingDidChange_) {
        allowsScalingDidChange_ = NO;
        [self forEachObserverRespondingToSelector:@selector(model:didChangeAllowsScaling:) do:^(id<ModelObserver> observer) {
            [observer model:self didChangeAllowsScaling:_allowsScaling];
        }];
    }

    if (allowsShearingDidChange_) {
        allowsShearingDidChange_ = NO;
        [self forEachObserverRespondingToSelector:@selector(model:didChangeAllowsShearing:) do:^(id<ModelObserver> observer) {
            [observer model:self didChangeAllowsShearing:_allowsShearing];
        }];
    }

    if (interpolationAbscissaDidChange_) {
        interpolationAbscissaDidChange_ = NO;
        [self forEachObserverRespondingToSelector:@selector(model:didChangeInterpolationAbscissa:) do:^(id<ModelObserver> observer) {
            [observer model:self didChangeInterpolationAbscissa:_interpolationAbscissa];
        }];
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

@end
