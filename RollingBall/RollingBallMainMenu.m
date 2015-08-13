//
//  RollingBallMainMenu.m
//  RollingBall
//
//  Created by peter on 6/9/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import "RollingBallMainMenu.h"
#import "RollingBallMyScene.h"

@implementation RollingBallMainMenu

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        SKScene *myScene = [[RollingBallMyScene alloc] init];
        [self presentScene:myScene];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
