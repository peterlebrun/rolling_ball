//
//  RBTracker.h
//  RollingBall
//
//  Created by peter on 7/29/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@interface RBTracker : NSObject

@property (strong, nonatomic) NSString *currentSceneName;

+ (instancetype)sharedInstance;
- (void)logAction:(NSString *)action category:(NSString *)category;

@end