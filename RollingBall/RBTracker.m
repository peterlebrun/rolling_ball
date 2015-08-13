//
//  RBTracker.m
//  RollingBall
//
//  Created by peter on 7/29/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import "RBTracker.h"
#import "RBGameManager.h"
#import "GAIDictionaryBuilder.h"

@interface RBTracker ()
@property (nonatomic, strong) id<GAITracker>tracker;
@property (nonatomic, strong) NSString *trackingCode;
@end

@implementation RBTracker
@synthesize currentSceneName;

/*
 * Initialize as singleton object using sharedInstance pattern; available throughout game
 */
+ (instancetype)sharedInstance {
    static dispatch_once_t pred;
    static RBTracker *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[RBTracker alloc] init];
    });
    return sharedInstance;
}

- (id<GAITracker>)tracker {
    if (!_tracker) {
        _tracker = [[GAI sharedInstance] trackerWithTrackingId:[self trackingCode]];
        
        // Make sure sampling rate is consistent
        [_tracker set:kGAISampleRate value:@"50.0"];
    } else {
        _tracker = [[GAI sharedInstance] defaultTracker];
    }
    
    return _tracker;
}

- (NSString *)trackingCode {
    return @"UA-53294112-1";
}

- (NSString *)currentSceneName {
    // The getter should never be called before the setter
    // Providing bogus name to log it
    if (!currentSceneName) {
        currentSceneName = @"noSceneName";
    }
    return currentSceneName;
}

- (void)setCurrentSceneName:(NSString *)name {
    if (name) {
        currentSceneName = name;
    
        [self.tracker set:kGAIScreenName value:currentSceneName];
        [self.tracker send:[[GAIDictionaryBuilder createAppView] build]];
    } else {
        [self.tracker set:kGAIScreenName value:nil];
    }
}

- (void)logAction:(NSString *)action category:(NSString *)category {
    [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:category
                                                               action:[self currentSceneName]
                                                                label:action
                                                                value:nil] build]];
}

- (void)dealloc
{
    [self setCurrentSceneName:nil];
    // implement -dealloc & remove abort() when refactoring for
    // non-singleton use.
    abort();
}

@end
