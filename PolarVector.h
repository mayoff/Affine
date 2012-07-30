/*
Created by Rob Mayoff on 7/29/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

typedef struct PolarVector {
    CGFloat r; // radius
    CGFloat a; // angle in radians
} PolarVector;

typedef struct PolarAffineTransform {
    PolarVector u;
    PolarVector v;
    CGPoint t;
} PolarAffineTransform;

static inline PolarVector PolarVectorFromCGPoint(CGPoint p) {
    PolarVector v;
    v.r = hypotf(p.y, p.x);
    v.a = atan2f(p.y, p.x);
    return v;
}

static inline CGPoint pointFromPolarVector(PolarVector v) {
    return CGPointMake(v.r * cosf(v.a), v.r * sinf(v.a));
}

static inline PolarVector PolarVectorFlip(PolarVector v) {
    v.r = -v.r;
    if (v.a < 0) {
        v.a += M_PI;
    } else {
        v.a -= M_PI;
    }
    return v;
}

static inline PolarAffineTransform PolarAffineTransformFromAffineTransform(CGAffineTransform rt) {
    CGPoint *p = (CGPoint *)&rt.a;
    PolarAffineTransform pt;
    pt.u = PolarVectorFromCGPoint(p[0]);
    pt.v = PolarVectorFromCGPoint(p[1]);
    pt.t = p[2];

    // Cross-product of u and v is negative if one of them is flipped relative to the other.
    if (rt.a * rt.d - rt.b * rt.c < 0) {
        // Interpolation works better if I represent the flipped vector with a negative radius.
        if (rt.a < rt.d) {
            pt.u = PolarVectorFlip(pt.u);
        } else {
            pt.v = PolarVectorFlip(pt.v);
        }
    }

    return pt;
}

static inline CGAffineTransform affineTransformFromPolarAffineTransform(PolarAffineTransform pt) {
    CGAffineTransform rt;
    CGPoint *p = (CGPoint *)&rt.a;
    p[0] = pointFromPolarVector(pt.u);
    p[1] = pointFromPolarVector(pt.v);
    p[2] = pt.t;
    return rt;
}
