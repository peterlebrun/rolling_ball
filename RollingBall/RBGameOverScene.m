//
//  RBGameOverScene.m
//  RollingBall
//
//  Display game over scene
//  Ideally, this will change depending on how the game ended
//
//  Created by peter on 7/12/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import "RBGameOverScene.h"
#import "RBGameScene.h"
#import "RBOptionsScene.h"
#import "RBRemoveAdsScene.h"
#import "RBHomeScene.h"

@implementation RBGameOverScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        [[self tracker] setCurrentSceneName:@"GameOverScene"];
        
        [self setBackgroundColor:[SKColor colorWithRed:1 green:1 blue:0.8 alpha:1]];
        [self setupScreen];
    }
    return self;
}

/*
 * Check for restart game event
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch     = [touches anyObject];
    CGPoint location   = [touch locationInNode:self];
    SKSpriteNode *node = (SKSpriteNode *)[self nodeAtPoint:location];
    
    SKColor *gray = [SKColor grayColor];
    
    if ([node.name isEqualToString:@"removeAds"] ||
        [node.name isEqualToString:@"play"]      ||
        [node.name isEqualToString:@"options"]   ||
        [node.name isEqualToString:@"home"]
        ){
        [node setColor:gray];
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
    
    if ([node.name isEqualToString:@"removeAds"] ||
        [node.name isEqualToString:@"play"]      ||
        [node.name isEqualToString:@"options"]   ||
        [node.name isEqualToString:@"home"]
        ){
        [button setColor:[SKColor whiteColor]];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch     = [touches anyObject];
    CGPoint location   = [touch locationInNode:self];
    SKSpriteNode *node = (SKSpriteNode *)[self nodeAtPoint:location];
    
    SKColor *white = [SKColor whiteColor];
    if ([node.name isEqualToString:@"removeAds"]) {
        [node setColor:white];
        
        [self.tracker logAction:[NSString stringWithFormat:@"%@-%d", node.name, self.gameManager.gameOverCode] category:@"touch"];
        [self.scene.view presentScene:[RBRemoveAdsScene sceneWithSize:self.size] transition:[self reveal]];
    }
    if ([node.name isEqualToString:@"play"]) {
        [node setColor:white];
        [self.tracker logAction:[NSString stringWithFormat:@"%@-%d", node.name, self.gameManager.gameOverCode]  category:@"touch"];
        [self.scene.view presentScene:[RBGameScene sceneWithSize:self.size] transition:[self reveal]];
    }
    if ([node.name isEqualToString:@"options"]) {
        [node setColor:white];
        [self.tracker logAction:[NSString stringWithFormat:@"%@-%d", node.name, self.gameManager.gameOverCode]  category:@"touch"];
        [self.scene.view presentScene:[RBOptionsScene sceneWithSize:self.size] transition:[self reveal]];
    }
    if ([node.name isEqualToString:@"home"]) {
        [node setColor:white];
        [self.tracker logAction:[NSString stringWithFormat:@"%@-%d", node.name, self.gameManager.gameOverCode]  category:@"touch"];
        [self.scene.view presentScene:[RBHomeScene sceneWithSize:self.size] transition:[self reveal]];
    }
}

/*
 * Display buttons and messaging
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
    int r7 = r6 - m;
    
    SKColor *black = [SKColor blackColor];
    
    NSString *gameOverLabel = @"";
    
    switch (self.gameManager.gameOverCode) {
        case WIN:
            gameOverLabel = @"you won!";
            break;
        case HIGHSCORE:
            gameOverLabel = @"new high score!";
            break;
        case TIMEOUT:
            gameOverLabel = @"time out";
            break;
        case DIED:
            gameOverLabel = @"you died";
            break;
    }
    
    [self.tracker logAction:gameOverLabel category:@"endGameWithCode"];

    [self addChild:[self ballAt:  CGPointMake(x, r1) size:48 name:@""]];
    [self addChild:[self labelAt: CGPointMake(x, r2) text:@"rolling ball" fontSize:33 name:@"" color:black]];
    [self addChild:[self labelAt: CGPointMake(x, y ) text:gameOverLabel   fontSize:33 name:@"" color:black]];
    [self addChild:[self buttonAt:CGPointMake(x, r4) text:@"get more time"  name:@"removeAds"]];
    [self addChild:[self buttonAt:CGPointMake(x, r5) text:@"play again"     name:@"play"]];
    [self addChild:[self buttonAt:CGPointMake(x, r6) text:@"options"        name:@"options"]];
    [self addChild:[self buttonAt:CGPointMake(x, r7) text:@"return to home" name:@"home"]];
}

@end
