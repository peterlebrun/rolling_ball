//
//  RBOptionsScene.m
//  RollingBall
//
//  Created by peter on 7/21/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import "RBOptionsScene.h"
#import "RBHomeScene.h"

@implementation RBOptionsScene
/*
 * Initialize a new screen
 */
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        [[self tracker] setCurrentSceneName:@"OptionsScene"];
        
        [self setBackgroundColor:[SKColor colorWithRed:1 green:1 blue:0.8 alpha:1]];
        [self setupScreen];
    }
    return self;
}

/*
 * Check what action to take when the user taps
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch     = [touches anyObject];
    CGPoint location   = [touch locationInNode:self];
    SKSpriteNode *node = (SKSpriteNode *)[self nodeAtPoint:location];
    
    SKSpriteNode *button;
    SKLabelNode *label;
    if ([node isKindOfClass:[SKLabelNode class]]) {
        button = (SKSpriteNode *)[node parent];
        label = (SKLabelNode *)node;
    }
    else if ([node isKindOfClass:[SKSpriteNode class]]) {
        button = node;
        label = (SKLabelNode *)[node childNodeWithName:node.name];
    }
    
    // Set buttons to gray on touch, set to white on release, to give feedback to user
    SKColor *gray = [SKColor grayColor];
    if ([node.name isEqualToString:@"home"]) {
        [button setColor:gray];
        [self.tracker logAction:node.name category:@"touch"];
    } else if ([node.name isEqualToString:@"difficulty"] ||
               [node.name isEqualToString:@"sound"]      ||
               [node.name isEqualToString:@"vibration"]  ){
        [button setColor:gray];
        [self.tracker logAction:label.text category:@"touch"];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch     = [touches anyObject];
    CGPoint location   = [touch locationInNode:self];
    SKSpriteNode *node = (SKSpriteNode *)[self nodeAtPoint:location];
    
    SKSpriteNode *button;
    if ([node isKindOfClass:[SKLabelNode class]]) {
        button = (SKSpriteNode *)[node parent];
    } else {
        button = node;
    }
    
    if ([node.name isEqualToString:@"home"]  || [node.name isEqualToString:@"difficulty"] ||
        [node.name isEqualToString:@"sound"] || [node.name isEqualToString:@"vibration"] ){
        [button setColor:[SKColor whiteColor]];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch     = [touches anyObject];
    CGPoint location   = [touch locationInNode:self];
    SKSpriteNode *node = (SKSpriteNode *)[self nodeAtPoint:location];
    
    SKSpriteNode *button;
    SKLabelNode *label;
    if ([node isKindOfClass:[SKLabelNode class]]) {
        button = (SKSpriteNode *)[node parent];
        label = (SKLabelNode *)node;
    }
    else if ([node isKindOfClass:[SKSpriteNode class]]) {
        button = node;
        label = (SKLabelNode *)[node childNodeWithName:node.name];
    }
    
    // Set buttons to gray on touch, set to white on release, to give feedback to user
    SKColor *white = [SKColor whiteColor];
    if ([node.name isEqualToString:@"home"]) {
        [button setColor:white];
        [self.scene.view presentScene:[RBHomeScene sceneWithSize:self.size] transition:[self reveal]];
    } else {
        if ([node.name isEqualToString:@"difficulty"]) {
            [button setColor:white];
            if ([[self.gameManager difficulty] isEqualToString:EASY]) {
                [self.gameManager setDifficulty:MEDIUM];
                [label setText:@"difficulty: medium"];
            } else if ([[self.gameManager difficulty] isEqualToString:MEDIUM]) {
                [self.gameManager setDifficulty:HARD];
                [label setText:@"difficulty: hard"];
            } else if ([[self.gameManager difficulty] isEqualToString:HARD]) {
                [self.gameManager setDifficulty:EASY];
                [label setText:@"difficulty: easy"];
            }
        } else if ([node.name isEqualToString:@"sound"]) {
            [button setColor:white];
            [self.gameManager setPlaySound:(![self.gameManager playSound])];
            
            if ([self.gameManager playSound]) {
                [label setText:@"sound: on"];
            } else {
                [label setText:@"sound: off"];
            }
        } else if ([node.name isEqualToString:@"vibration"])   {
            [button setColor:white];
            [self.gameManager setPlayVibration:(![self.gameManager playVibration])];
            
            if ([self.gameManager playVibration]) {
                [label setText:@"vibration: on"];
            } else {
                [label setText:@"vibration: off"];
            }
        }
    }
}

/*
 * Set up all the visual stuff
 */
- (void)setupScreen {
    int x  = self.size.width / 2;
    int y  = (self.size.height / 2) + 85;
    int m  = 58; // m = margin
    int r1 = y + 110;
    int r2 = y + 45;
    int r4 = y  - m;
    int r5 = r4 - m;
    int r6 = r5 - m;
    /*
    int r7 = r6 - m;
    int r8 = r7 - m - 10;
     */
    
    NSString *difficultyText = [NSString stringWithFormat:@"difficulty: %@", [self.gameManager difficulty]];
    
    NSString *soundText;
    if ([self.gameManager playSound]) {
        soundText = @"sound: on";
    } else {
        soundText = @"sound: off";
    }
    
    NSString *vibrationText;
    if ([self.gameManager playVibration]) {
        vibrationText = @"vibration: on";
    } else {
        vibrationText = @"vibration: off";
    }
    
    SKColor *black = [SKColor blackColor];
    
    [self addChild:[self ballAt:  CGPointMake(x, r1) size:48 name:@""]];
    [self addChild:[self labelAt: CGPointMake(x, r2) text:@"rolling ball"   fontSize:33 name:@"" color:black]];
    [self addChild:[self buttonAt:CGPointMake(x, y ) text:difficultyText    name:@"difficulty"]];
    [self addChild:[self buttonAt:CGPointMake(x, r4) text:soundText         name:@"sound"     ]];
    [self addChild:[self buttonAt:CGPointMake(x, r5) text:vibrationText     name:@"vibration" ]];
    [self addChild:[self buttonAt:CGPointMake(x, r6) text:@"return to home" name:@"home"      ]];
}

@end