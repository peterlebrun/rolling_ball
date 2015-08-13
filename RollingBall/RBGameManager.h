//
//  RBGameManager.h
//  RollingBall
//
//  Created by peter on 7/15/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import <Foundation/Foundation.h>

// Constants representing game difficulty
static const NSString *EASY   = @"easy";
static const NSString *MEDIUM = @"medium";
static const NSString *HARD   = @"hard";

// Constants representing game over status
static const int WIN       = 1;
static const int HIGHSCORE = 2;
static const int TIMEOUT   = 3;
static const int DIED      = 4;

@interface RBGameManager : NSObject

+ (instancetype) sharedInstance;

#pragma mark - game play (not-persistent)
@property CGFloat timePerBall;
@property int gameOverCode;
@property BOOL hasNewHighScore;
@property (nonatomic, strong) NSString *state;

#pragma mark - game play (persistent)
@property (nonatomic, strong) NSString *difficulty;
@property BOOL playSound;
@property BOOL playVibration;
@property int highScore;

#pragma mark - in-app purchase flags
@property BOOL hasPaidToRemoveAds;
@property BOOL hasPaidForMoreTime;
@property BOOL hasPaidToGoPro;

#pragma mark - instructions flags
@property BOOL hasSeenInstructionsEasy;
@property BOOL hasSeenInstructionsMedium;
@property BOOL hasSeenInstructionsHard;

@end