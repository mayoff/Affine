/*
Created by Rob Mayoff on 7/29/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import "ObserverSet.h"
#import <objc/runtime.h>

@interface ObserverSetMessageProxy : NSObject {
    __weak ObserverSet *observers_;
}
- (id)initWithObserverSet:(ObserverSet *)observers;
@end

@implementation ObserverSet {
    NSCountedSet *observers_;
    NSCountedSet *pendingObservers_;
    ObserverSetMessageProxy *_proxy_cached;
}

- (NSString *)debugDescription {
    if (!observers_.count)
        return [super debugDescription];

    NSMutableString *string = [NSMutableString stringWithFormat:@"<%@: %p:", self.class, self];
    for (NSValue *wrapper in observers_) {
        [string appendString:@"\n\t"];
        [string appendString:[[wrapper nonretainedObjectValue] debugDescription]];
    }
    [string appendString:@"\n>"];
    return string;
}

- (void)addObserverObject:(id)observer {
    if (!observers_) {
        observers_ = [NSCountedSet set];
    }
    [observers_ addObject:[NSValue valueWithNonretainedObject:observer]];
}

- (void)removeObserverObject:(id)observer {
    NSValue *wrapper = [NSValue valueWithNonretainedObject:observer];
    [observers_ removeObject:wrapper];
    if (pendingObservers_) {
        [pendingObservers_ removeObject:wrapper];
    }
}

- (void)forEachObserverRespondingToSelector:(SEL)selector do:(void (^)(id))block {
    NSAssert(pendingObservers_ == nil, @"%@ tried to iterate observers while already iterating observers", self);
    pendingObservers_ = [observers_ copy];
    while (true) {
        id observer = [self nextPendingObserver];
        if (!observer)
            break;
        if ([observer respondsToSelector:selector]) {
            block(observer);
        }
    }
    pendingObservers_ = nil;
}

- (id)proxy {
    if (!_proxy_cached) {
        _proxy_cached = [[ObserverSetMessageProxy alloc] initWithObserverSet:self];
    }
    return _proxy_cached;
}

- (id)nextPendingObserver {
    NSValue *wrapper = pendingObservers_.anyObject;
    if (!wrapper)
        return nil;
    for (NSUInteger i = [pendingObservers_ countForObject:wrapper]; i > 0; --i) {
        [pendingObservers_ removeObject:wrapper];
    }
    return wrapper.nonretainedObjectValue;
}

@end

@implementation ObserverSetMessageProxy

- (id)initWithObserverSet:(ObserverSet *)observers {
    if (!(self = [super init]))
        return nil;

    observers_ = observers;

    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [observers_ forEachObserverRespondingToSelector:anInvocation.selector do:^(id observer) {
        [anInvocation invokeWithTarget:observer];
    }];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    Protocol *protocol = observers_.protocol;
    NSAssert(protocol != nil, @"%@ proxy received message but protocol not set", observers_);
    struct objc_method_description description = protocol_getMethodDescription(protocol, aSelector, YES, YES);
    if (!description.name) {
        description = protocol_getMethodDescription(protocol, aSelector, NO, YES);
    }
    NSAssert(description.name != NULL, @"%@ proxy received message %s that is not in protocol %@", observers_, sel_getName(aSelector), protocol);
    return [NSMethodSignature signatureWithObjCTypes:description.types];
}

@end
