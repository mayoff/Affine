/*
Created by Rob Mayoff on 7/29/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

typedef struct PolarVector {
    CGFloat r; // radius
    CGFloat a; // angle in radians
} PolarVector;

static inline PolarVector PolarVectorFromCGPoint(CGPoint p) {
    PolarVector v;
    v.r = hypotf(p.y, p.x);
    v.a = atan2f(p.y, p.x);
    return v;
}

static inline CGPoint pointFromPolarVector(PolarVector v) {
    return CGPointMake(v.r * cosf(v.a), v.r * sinf(v.a));
}

