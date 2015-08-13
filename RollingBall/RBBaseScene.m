//
//  RBBaseScene.m
//  RollingBall
//
//  Base scene which is extended by all other scenes in this app
//  Provides basic methods for providing visual elements
//
//  Created by peter on 7/12/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import "RBBaseScene.h"
#import "RBGameManager.h"
#import "RBTracker.h"
#import "GAIDictionaryBuilder.h"

@implementation RBBaseScene
@synthesize gameManager;
@synthesize tracker;
@synthesize reveal;

- (id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {

    }
    return self;
}

/*
 * Access gameManager as singleton
 */
- (RBGameManager *)gameManager {
    if (!gameManager) {
        [self setGameManager:[RBGameManager sharedInstance]];
    }
    return gameManager;
}

/*
 * Access tracker as singleton (Wraps GA)
 */
- (RBTracker *)tracker {
    if (!tracker) {
        [self setTracker:[RBTracker sharedInstance]];
    }
    return tracker;
}

/*
 * Called from a bunch of places, basically just some syntactic sugar
 */
- (SKTransition *)reveal {
    if (!reveal) {
        [self setReveal:[SKTransition revealWithDirection:SKTransitionDirectionDown duration:0.5]];
    }
    return reveal;
}

/*
 * Returns label with specified attributes
 */
- (SKLabelNode *)labelAt:(CGPoint)point text:(NSString *)text fontSize:(int)fontSize name:(NSString *)name color:(SKColor *)color {
    
    // Toss up between Helvetica-Light and GillSans-Light and AvenirNext-Ultralight WINNER: Avenir-Light
    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Avenir-Light"];
    
    label.text      = text;
    label.name      = name;
    label.position  = point;
    label.fontColor = color;
    label.fontSize  = fontSize;
    
    return label;
}

/*
 * Returns rectangle with specified attributes
 */
- (SKSpriteNode *)rectangleAt:(CGPoint)point size:(CGSize)size name:(NSString *)name color:(SKColor *)color {
    
    SKSpriteNode *rect = [SKSpriteNode spriteNodeWithColor:color size:size];
    
    rect.position = point;
    rect.name     = name;
    
    return rect;
}

/*
 * Returns ball for display with specified attributes (not a rolling ball, just for the logo)
 */
- (SKShapeNode *)ballAt:(CGPoint)point size:(int)diameter name:(NSString *)name {
    
    SKShapeNode *ball = [[SKShapeNode alloc] init];
    
    CGMutablePathRef myPath = CGPathCreateMutable();
    CGPathAddArc(myPath, NULL, 0,0, diameter / 2, 0, M_PI*2, YES);
    ball.path = myPath;
    CGPathRelease(myPath);
    
    ball.name     = name;
    ball.position = point;
    
    ball.lineWidth = 0;
    ball.fillColor = [SKColor redColor];
    
    return ball;
}

/*
 * Returns button - just a rectangle with a label in it
 */
- (SKSpriteNode *)buttonAt:(CGPoint)point text:(NSString *)text name:(NSString *)name {
    // Sprite node button has origin at center I believe
    SKSpriteNode *button = [self rectangleAt:point size:CGSizeMake(170, 48) name:name color:[SKColor whiteColor]];
    
    // Label position center is relative to button center
    [button addChild:[self labelAt:CGPointMake(0, -6) text:text fontSize:18 name:name color:[SKColor blackColor]]];
    
    return button;
}

/*
 * Remove all child objects
 * For all SKShapeNodes, set childPath to nil
 * Be sure to set path to nil first; otherwise risk of memory leaks
 */
- (void) dealloc {
    // Funny story - I think [self children] refers to EVERYTHING - not just child NODES
    // So, this pattern below should address our memory concerns as well as make sure
    // that we only remove dead children
    for (NSObject *child in [self children]) {
        if ([child isKindOfClass:[SKShapeNode class]]) {
            [(SKShapeNode *)child setPath:nil];
        }
        if ([child isKindOfClass:[SKNode class]]) {
            [(SKNode *)child removeFromParent];
        }
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

@end