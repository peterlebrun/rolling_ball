//
//  RBBaseScene.h
//
//  Created by peter on 7/12/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "RBGameManager.h"
#import "RBTracker.h"

@interface RBBaseScene : SKScene

@property (nonatomic) RBGameManager *gameManager;
@property (nonatomic) RBTracker *tracker;
@property (nonatomic) SKTransition *reveal;

- (SKLabelNode *)labelAt:(CGPoint)point text:(NSString *)text fontSize:(int)fontSize name:(NSString *)name color:(SKColor *)color;
- (SKSpriteNode *)rectangleAt:(CGPoint)point size:(CGSize)size name:(NSString *)name color:(SKColor *)color;
- (SKShapeNode *)ballAt:(CGPoint)point size:(int)diameter name:(NSString *)name;
- (SKSpriteNode *)buttonAt:(CGPoint)point text:(NSString *)text name:(NSString *)name;

@end