/*
Created by Rob Mayoff on 7/28/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import <Foundation/Foundation.h>

@protocol ModelObserver;

@interface Model : NSObject

@property (nonatomic) BOOL allowsShearing;
@property (nonatomic) BOOL allowsScaling;

@property (nonatomic) CGAffineTransform preset0;
@property (nonatomic) CGAffineTransform preset1;

- (void)setCurrentPresetToTransform:(CGAffineTransform)transform;

@property (nonatomic) CGFloat interpolationAbscissa; // between 0 and 1 inclusive

@property (nonatomic, readonly) CGAffineTransform interpolatedTransform;

// I don't retain observer.
- (void)addModelObserver:(id<ModelObserver>)observer;
- (void)removeModelObserver:(id<ModelObserver>)observer;

@end

@protocol ModelObserver <NSObject>

@optional

- (void)model:(Model *)model didChangeInterpolationAbscissa:(CGFloat)abscissa;

- (void)model:(Model *)model didChangeInterpolatedTransform:(CGAffineTransform)transform;

- (void)model:(Model *)model didChangeAllowsShearing:(BOOL)allowsShearing;

- (void)model:(Model *)model didChangeAllowsScaling:(BOOL)allowsScaling;

@end
