//
//  RBGameManager.m
//  RollingBall
//
//  Essentially just a wrapper for the plist
//  Overrides setters and getters for all properties.
//  Note that every set method writes to file
//
//  Created by peter on 7/15/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import "RBGameManager.h"

@interface RBGameManager()
/*
 * Location of the plist file
 */
@property NSString *filePath;

/*
 * The data containing all the game settings
 */
@property NSMutableDictionary *data;

@end

@implementation RBGameManager

#pragma mark - class handlers
/*
 * Initialize as singleton object using sharedInstance pattern; available throughout game
 */
+(instancetype)sharedInstance {
    static dispatch_once_t pred;
    static RBGameManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[RBGameManager alloc] init];
    });
    return sharedInstance;
}

/*
 * Read values from p list; make available throughout game
 */
- (RBGameManager *)init {
    if ([super init]) {
        [self setFilePath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"gameSettings.plist"]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
            [self setData:[[NSMutableDictionary alloc] initWithContentsOfFile:self.filePath]];
        } else {
            // Doesn't exist, start with an empty dictionary
            [self setData:[[NSMutableDictionary alloc] init]];

            // initial values
            [self setDifficulty:EASY];
            [self setPlaySound:YES];
            [self setPlayVibration:YES];
            [self setHighScore:0];
            
            [self setHasPaidToRemoveAds:NO];
            [self setHasPaidForMoreTime:NO];
            [self setHasPaidToGoPro:NO];
            
            [self setHasSeenInstructionsEasy:NO];
            [self setHasSeenInstructionsMedium:NO];
            [self setHasSeenInstructionsHard:NO];
        }
    }
    return self;
}

/*
 * Just a nice little wrapper, some syntactic sugar if you will
 */
- (void)writeToFile {
    [self.data writeToFile:self.filePath atomically:YES];
}

- (void)dealloc
{
    // implement -dealloc & remove abort() when refactoring for
    // non-singleton use.
    abort();
}

#pragma mark - game play (not-persistent)
@synthesize timePerBall;
- (CGFloat)timePerBall {
    if ([self hasPaidForMoreTime]) {
        return 10.0;
    } else {
        return 4.0;
    }
}

@synthesize gameOverCode;
- (int)gameOverCode {
    if (!gameOverCode) {
        [self setGameOverCode:WIN];
    }
    return gameOverCode;
}

- (void)setGameOverCode:(int)code {
    gameOverCode = code;
}

@synthesize hasNewHighScore;
- (BOOL)hasNewHighScore {
    if ((int)hasNewHighScore == nil) {
        hasNewHighScore = NO;
    }
    return hasNewHighScore;
}

- (void)setHasNewHighScore:(BOOL)flag{
    hasNewHighScore = flag;
}

#pragma mark - game play (persistent)
@synthesize difficulty;
- (NSString *)difficulty {
    if (!difficulty) {
        difficulty = self.data[@"difficulty"];
    }
    return difficulty;
}

- (void)setDifficulty:(NSString *)setting {
    difficulty = setting;
    [self.data setObject:[NSString stringWithString:difficulty] forKey:@"difficulty"];
    [self writeToFile];
}

@synthesize playSound;
- (BOOL)playSound {
    // cast to int because it's a bool, which will return NO if not initialized :/
    if ((int)playSound == nil) {
        playSound = [self.data[@"playSound"] boolValue];
    }
    return playSound;
}

- (void)setPlaySound:(BOOL)flag {
    playSound = flag;
    [self.data setObject:[NSNumber numberWithBool:playSound] forKey:@"playSound"];
    [self writeToFile];
}

@synthesize playVibration;
- (BOOL)playVibration {
    if ((int)playVibration == nil) {
        playVibration = [self.data[@"playVibration"] boolValue];
    }
    return playVibration;
}

- (void)setPlayVibration:(BOOL)flag {
    playVibration = flag;
    [self.data setObject:[NSNumber numberWithBool:playVibration] forKey:@"playVibration"];
    [self writeToFile];
}

@synthesize highScore;
- (int)highScore {
    if (!highScore) {
        highScore = [self.data[@"highScore"] intValue];
    }
    return highScore;
}

- (void)setHighScore:(int)score {
    highScore = score;
    [self.data setObject:[NSNumber numberWithInt:highScore] forKey:@"highScore"];
    [self writeToFile];
}

#pragma mark - in-app purchase flags
@synthesize hasPaidToRemoveAds;
- (BOOL)hasPaidToRemoveAds {
    if ((int)hasPaidToRemoveAds == nil) {
        hasPaidToRemoveAds = [self.data[@"hasPaidToRemoveAds"] boolValue];
    }
    return hasPaidToRemoveAds;
}

- (void)setHasPaidToRemoveAds:(BOOL)flag {
    hasPaidToRemoveAds = flag;
    
    if (hasPaidToRemoveAds) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"hideAds" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"disableRemoveAdsButton" object:nil];
    }
    
    [self.data setObject:[NSNumber numberWithBool:hasPaidToRemoveAds] forKey:@"hasPaidToRemoveAds"];
    [self writeToFile];
    
    if (hasPaidToRemoveAds && hasPaidForMoreTime && !hasPaidToGoPro) {
        [self setHasPaidToGoPro:YES];
    }
}

@synthesize hasPaidForMoreTime;
- (BOOL)hasPaidForMoreTime {
    if ((int)hasPaidForMoreTime == nil) {
        hasPaidForMoreTime = [self.data[@"hasPaidForMoreTime"] boolValue];
    }
    return hasPaidForMoreTime;
}

- (void)setHasPaidForMoreTime:(BOOL)flag {
    hasPaidForMoreTime = flag;
    
    if (hasPaidForMoreTime) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"disableMoreTimeButton" object:nil];
    }
    
    [self.data setObject:[NSNumber numberWithBool:hasPaidForMoreTime] forKey:@"hasPaidForMoreTime"];
    [self writeToFile];
    
    if (hasPaidForMoreTime && hasPaidToRemoveAds && !hasPaidToGoPro) {
        [self setHasPaidToGoPro:YES];
    }
}

@synthesize hasPaidToGoPro;
- (BOOL)hasPaidToGoPro {
    if ((int)hasPaidToGoPro == nil) {
        hasPaidToGoPro = [self.data[@"hasPaidToGoPro"] boolValue];
    }
    return hasPaidToGoPro;
}

- (void)setHasPaidToGoPro:(BOOL)flag {
    hasPaidToGoPro = flag;
    
    if (hasPaidToGoPro) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"disableGoProButton" object:nil];
    }
    
    [self.data setObject:[NSNumber numberWithBool:hasPaidToGoPro] forKey:@"hasPaidToGoPro"];
    [self writeToFile];
    
    if (hasPaidToGoPro && !(hasPaidForMoreTime || hasPaidToRemoveAds)) {
        [self setHasPaidToRemoveAds:YES];
        [self setHasPaidForMoreTime:YES];
    }
}

#pragma mark - instructional messaging
@synthesize hasSeenInstructionsEasy;
- (BOOL)hasSeenInstructionsEasy {
    if ((int)hasSeenInstructionsEasy == nil) {
        hasSeenInstructionsEasy = [self.data[@"hasSeenInstructionsEasy"] boolValue];
    }
    return hasSeenInstructionsEasy;
}

- (void)setHasSeenInstructionsEasy:(BOOL)flag {
    hasSeenInstructionsEasy = flag;
    
    [self.data setObject:[NSNumber numberWithBool:hasSeenInstructionsEasy] forKey:@"hasSeenInstructionsEasy"];
    [self writeToFile];
}

@synthesize hasSeenInstructionsMedium;
- (BOOL)hasSeenInstructionsMedium {
    if ((int)hasSeenInstructionsMedium == nil) {
        hasSeenInstructionsMedium = [self.data[@"hasSeenInstructionsMedium"] boolValue];
    }
    return hasSeenInstructionsMedium;
}

- (void)setHasSeenInstructionsMedium:(BOOL)flag {
    hasSeenInstructionsEasy = flag;
    
    [self.data setObject:[NSNumber numberWithBool:hasSeenInstructionsMedium] forKey:@"hasSeenInstructionsMedium"];
    [self writeToFile];
}

@synthesize hasSeenInstructionsHard;
- (BOOL)hasSeenInstructionsHard {
    if ((int)hasSeenInstructionsHard == nil) {
        hasSeenInstructionsHard = [self.data[@"hasSeenInstructionsHard"] boolValue];
    }
    return hasSeenInstructionsHard;
}

- (void)setHasSeenInstructionsHard:(BOOL)flag {
    hasSeenInstructionsHard = flag;
    
    [self.data setObject:[NSNumber numberWithBool:hasSeenInstructionsHard] forKey:@"hasSeenInstructionsHard"];
    [self writeToFile];
}

@end