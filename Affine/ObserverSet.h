/*
Created by Rob Mayoff on 7/29/12.
Copyright (c) 2012 Rob Mayoff. All rights reserved.
*/

#import <Foundation/Foundation.h>

/**
I track a set of observer objects, without retaining them.  You can add and remove observers to the set, and you can iterate over those members of the set that respond to a specific selector.

In addition, you can send me any message.  If I do not otherwise recognize the message, I forward it to all of the observers that do recognize it.
*/

@interface ObserverSet : NSObject

// I keep a non-retained reference to `observer`.  If you add an observer multiple times, you must remove it the same number of times for me to forget about it.
- (void)addObserverObject:(id)observer;

// I remove a reference to `observer`.  I may have other references to it.
- (void)removeObserverObject:(id)observer;

// I iterate over the observers.  I call `block` once one each one that responds to `selector`.  I only call `block` at most once for each observer, regardless of how many references I have to it (from multiple `addObserverObject:` messages.  It is safe to send me `addObserverObject:` and `removeObserverObject:` messages from `block`.
- (void)forEachObserverRespondingToSelector:(SEL)selector do:(void (^)(id observer))block;

// The protocol adopted by the observers.  You need to set this if you want to use my message proxy.  Use `@protocol(ProtocolName)` to get the Protocol object at compile-time.
@property (nonatomic) Protocol *protocol;

// If you send a message to this proxy object, I will forward it to every observer that understands the message selector.  You must set my `protocol` property first.
@property (nonatomic, readonly) id proxy;

@end
