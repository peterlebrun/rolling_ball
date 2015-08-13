//
//  RBGameScene.m
//  RollingBall
//
//  Represents a playable level; encompasses all functions related to that
//
//  Created by peter on 7/12/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

// I really like the cascading that has happened here
#import "RBGameScene.h"
#import "RBHomeScene.h"
#import "RBGameOverScene.h"
#import <SpriteKit/SpriteKit.h>
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioToolbox.h>

/*
 * Bitmask representing the ball
 */
static const uint32_t ballCategory = 0x1 << 0;

/*
 * Bitmask representing the post
 */
static const uint32_t holeCategory = 0x1 << 1;

/*
 * Diameter of rolling balls
 */
static const int ballDiameter = 30;

/*
 * Diameter of posts of success
 */
static const int postDiameter = 40;

/*
 * Height only of the score box
 */
static const int scoreBoxHeight = 70;

/*
 * Height of the top status bar
 */
static const int statusBarHeight = 20;

/*
 * Height allowing for the status bar and the score box
 */
static const int topMargin = scoreBoxHeight + statusBarHeight;

/*
 * Height of the iAd banner
 */
static const int bottomMargin = 50;

/*
 * Time between calling the timer update
 */
static const CGFloat timeInterval = 0.01;

@interface RBGameScene ()
/*
 * We divide the game scene into 9 "origins" for the posts
 * For each posts, it selects an origin at random
 * This is how we avoid overlap
 * This is technically an array of points
 * See getRandomPoint for instruction on how we translate this to a post location
 */
@property (strong, nonatomic) NSMutableArray *postOrigins;

/*
 * The width of one of the post origins above
 */
@property int subdivisionWidth;

/*
 * The height of one of the post origins above
 */
@property int subdivisionHeight;

/*
 * Current game difficulty level - One of EASY, MEDIUM, HARD
 * Constants are defined in the public interface to this class
 */
@property (nonatomic, strong) NSString *difficulty;

/*
 * Level currently being played; ranges from 1 to 8
 */
@property int level;

/*
 * Number of balls in level without successful post collision
 */
@property int ballsRemaining;

/*
 * Time remaining in this level
 */
@property CGFloat timeRemaining;

/*
 * Timer keeping track of the level
 */
@property (strong, nonatomic) NSTimer *timer;

/*
 * Bitmask used to track post/ball collisions
 */
@property int colorCategories;

/*
 * Current score
 */
@property int score;

/*
 * Colors used for posts and rolling balls
 */
@property (strong, nonatomic) NSArray *colors;

/*
 * Interact with user's actions
 */
@property (strong, nonatomic) CMMotionManager *motionManager;

/*
 * Used only for logging
 */
@property (strong, nonatomic) NSString *difficultyLevelString;

/*
 *
 */
@property CFAbsoluteTime levelEndTime;

@property CGFloat physicsWorldSpeed;

@property (strong, nonatomic) SKSpriteNode *scoreBox;

@property BOOL isPaused;

@end

@implementation RBGameScene
/*
 * We synthesize these so we can override the setter
 */
@synthesize score;

/*
 *
 */
@synthesize level;

/*
 *
 */
@synthesize timeRemaining;

/*
 *
 */
@synthesize difficulty;

@synthesize physicsWorldSpeed;

@synthesize isPaused;

@synthesize scoreBox;

/*
 * Define getter so we can override setter below
 */
- (int)score {
    return score;
}

- (SKSpriteNode *)scoreBox {
    if (scoreBox == nil) {
        scoreBox = (SKSpriteNode *)[self childNodeWithName:@"scoreBox"];
    }
    return scoreBox;
}

/*
 * Every time we update the score, check if it's a new high score
 */
- (void)setScore:(int)updatedScore {
    if (!score) { score = 0; }

    score = updatedScore;
    
    [(SKLabelNode *)[[self scoreBox] childNodeWithName:@"score"] setText:[NSString stringWithFormat:@"%05u", score]];
    
    if (score > self.gameManager.highScore) {
        [self.gameManager setHighScore:score];
        
        SKLabelNode *hs = (SKLabelNode *)[[self scoreBox] childNodeWithName:@"highScore"];
        [hs setText:[NSString stringWithFormat:@"high score: %05u", [self.gameManager highScore]]];
        [hs setColor:[SKColor redColor]];
        
        // We only want to tell them they got a new high score one time
        if (!self.gameManager.hasNewHighScore) {
            [self.gameManager setHasNewHighScore:YES];
            [self.gameManager setGameOverCode:HIGHSCORE];
        }
    }
}

- (int)level {
    return level;
}

- (void)setLevel:(int)currentLevel {
    if (!level) { level = 1; }
    level = currentLevel;
    
    [(SKLabelNode *)[[self scoreBox] childNodeWithName:@"level"] setText:[NSString stringWithFormat:@"level %d", level]];
}

- (NSString *)difficulty {
    return difficulty;
}

- (void)setDifficulty {
    difficulty = [self.gameManager difficulty];
    [(SKLabelNode *)[[self scoreBox] childNodeWithName:@"difficulty"] setText:difficulty];
}

- (NSString *)difficultyLevelString {
    if (!_difficultyLevelString) {
        [self setDifficultyLevelString:[NSString stringWithFormat:@"%@|%d", self.difficulty, self.level]];
    }
        
    return _difficultyLevelString;
}

- (BOOL)isPaused {
    return isPaused;
}

- (void)setIsPaused:(BOOL) flag {
    isPaused = flag;
    
    if (isPaused) {
        if (![self childNodeWithName:@"instructions"]) {
            [self displayPauseScreen];
        }
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        [self setPhysicsWorldSpeed:[self.physicsWorld speed]];
        [self.physicsWorld setSpeed:0.0];
    
        [self endTimer];
    } else {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
        [self.physicsWorld setSpeed:[self physicsWorldSpeed]];
        
        // Set path to nil on this ball, otherwise: MEMORY LEAK
        SKNode *canvas = [self childNodeWithName:@"canvas"];
        if (canvas) {
            [(SKShapeNode *)[canvas childNodeWithName:@"ball"] setPath:nil];
            [canvas removeFromParent];
        }
        
        [self startTimer];
    }
}

/*
 * Define getter so we can override setter below
 */
- (CGFloat)timeRemaining {
    return timeRemaining;
}

/*
 * Every time we update the score, check if it's a new high score
 */
- (void)setTimeRemaining:(CGFloat)updatedTime {
    if (![self isPaused]) {
        timeRemaining = updatedTime;

        if (timeRemaining <= 0) { timeRemaining = 0.0; }
    
        NSString *timeText = [NSString stringWithFormat:@"%.2f", timeRemaining];
        [(SKLabelNode *)[[self scoreBox] childNodeWithName:@"timeRemaining"] setText:timeText];
    }
}

/*
 * Colors of the rolling balls and posts
 */
- (NSArray *)colors {
    if (!_colors) {
        [self setColors: @[[SKColor blueColor],
                           [SKColor redColor],
                           [SKColor greenColor],
                           [SKColor yellowColor],
                           [SKColor orangeColor],
                           [SKColor purpleColor],
                           [SKColor cyanColor],
                           [SKColor darkGrayColor]]];
    }
    
    return _colors;
}

/*
 * All the things that only need to happen once
 * These are all the actions that only need to happen once
 * (i.e. things we don't want to happen each time a new level loads)
 */
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        [[self tracker] setCurrentSceneName:@"GameScene"];

        [self setScaleMode:SKSceneScaleModeAspectFill];
        [self setBackgroundColor:[SKColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1]];
        [self setPhysicsBody:[SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, 50, self.size.width, self.size.height - 70 - 50 - 20)]];
        
        [self.physicsBody setCollisionBitMask:0];
        [self.physicsBody setContactTestBitMask:0];
        
        [self.physicsWorld setGravity:CGVectorMake(0,0)];
        [self.physicsWorld setContactDelegate:self];
        
        [self setMotionManager:[[CMMotionManager alloc] init]];
        [self.motionManager setDeviceMotionUpdateInterval:.2];
        [self.motionManager startDeviceMotionUpdates];
        
        [self setupScoreBox];
        [self setupBottomBox];
        [self setupPostOrigins];
        
        [self setScore:0];
        [self setLevel:1];
        [self setDifficulty];

        [self.tracker logAction:self.difficulty category:@"startGameWithDifficulty"];
        
        [self setupLevel];
        
        if (([self.difficulty isEqualToString:EASY]   && ![self.gameManager hasSeenInstructionsEasy])   ||
            ([self.difficulty isEqualToString:MEDIUM] && ![self.gameManager hasSeenInstructionsMedium]) ||
            ([self.difficulty isEqualToString:HARD]   && ![self.gameManager hasSeenInstructionsHard])
            ){
            [self displayInstructions];
            [self setIsPaused:YES];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resigningActive) name:UIApplicationWillResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resigningActive) name:@"adBannerTapped" object:nil];
        
    }
    return self;
}

- (void)resigningActive {
    if (!isPaused) {
        [self setIsPaused:YES];
    }
}

/*
 * Tapping the screen will pause and unpause the game...
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    SKSpriteNode *node = (SKSpriteNode *)[self nodeAtPoint:[[touches anyObject] locationInNode:self]];

    if (![self isPaused]) {
        [self setIsPaused:YES];
    } else {
        if ([node.name isEqualToString:@"home"]) {
            SKNode *canvas = [self childNodeWithName:@"canvas"];
            [(SKSpriteNode *)[canvas childNodeWithName:@"home"] setColor:[SKColor grayColor]];
            [self.tracker logAction:node.name category:@"touch"];
        } else {
            if ([self childNodeWithName:@"instructions"] != nil) {
                
                if ([self.difficulty isEqualToString:EASY]) {
                    [self.gameManager setHasSeenInstructionsEasy:YES];
                } else if ([self.difficulty isEqualToString:MEDIUM]) {
                    [self.gameManager setHasSeenInstructionsMedium:YES];
                } else if ([self.difficulty isEqualToString:HARD]) {
                    [self.gameManager setHasSeenInstructionsHard:YES];
                }
            
                // Set path to nil on this ball, otherwise: MEMORY LEAK
                [(SKShapeNode *)[[self childNodeWithName:@"ball"] childNodeWithName:@"instructions"] setPath:nil];
                [[self childNodeWithName:@"instructions"] removeFromParent];
            }
            [self setIsPaused:NO];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    SKSpriteNode *node = (SKSpriteNode *)[self nodeAtPoint:[[touches anyObject] locationInNode:self]];
    SKNode *canvas = [self childNodeWithName:@"canvas"];
    
    if ([node.name isEqualToString:@"home"]) {
        [(SKSpriteNode *)[canvas childNodeWithName:@"home"] setColor:[SKColor grayColor]];
    } else {
        [(SKSpriteNode *)[canvas childNodeWithName:@"home"] setColor:[SKColor whiteColor]];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    SKSpriteNode *node = (SKSpriteNode *)[self nodeAtPoint:[[touches anyObject] locationInNode:self]];
    SKNode *canvas = [self childNodeWithName:@"canvas"];

    if ([node.name isEqualToString:@"home"]) {
        [(SKSpriteNode *)[canvas childNodeWithName:@"home"] setColor:[SKColor whiteColor]];
        [self.scene.view presentScene:[RBHomeScene sceneWithSize:self.size] transition:[self reveal]];
        [self.tracker logAction:@"returnToHome" category:@"gamePlay"];
    } else {
        [(SKSpriteNode *)[canvas childNodeWithName:@"home"] setColor:[SKColor whiteColor]];
    }
}

/*
 * Everything that needs to happen for each new level
 */
- (void)setupLevel {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    // Reset the difficulty level string for each new level
    [self setDifficultyLevelString:nil];
    [self.tracker logAction:self.difficultyLevelString category:@"startLevel"];
    [self setBallsRemaining:self.level];
    
    [self.gameManager timePerBall];
    [self setTimeRemaining:(self.level * [self.gameManager timePerBall])];
    [self setLevelEndTime:CFAbsoluteTimeGetCurrent() + self.timeRemaining];
    
    [self startTimer];
    [self setColorCategories:0x0];
    [self populatePostOrigins];
    [self clearPostsAndBalls];
    
    for (int i = 1; i <= self.level; i++) {
        [self addChild:[self newRollingBallWithIndex:(int)i]];
        [self addChild:[self newPostOfSuccessWithIndex:(int)i]];
    }
}

/*
 * Returns a new rolling ball, to be added to the scene
 * We use the index to keep track of what color the ball is
 */
- (SKShapeNode *)newRollingBallWithIndex:(int)index {
    SKShapeNode *rollingBall = [[SKShapeNode alloc] init];
    
    CGMutablePathRef myPath = CGPathCreateMutable();
    CGPathAddArc(myPath, NULL, 0, 0, ballDiameter / 2, 0, M_PI*2, YES);
    rollingBall.path = myPath;
    CGPathRelease(myPath);

    rollingBall.fillColor = [self colors][index - 1];
    rollingBall.lineWidth = 0;
    rollingBall.glowWidth = 0.5;
    
    rollingBall.name = @"rollingBall";
    rollingBall.position = CGPointMake(ballDiameter + (arc4random() % (int)(self.frame.size.width - ballDiameter)),
                                       ballDiameter + 50 + (arc4random() % (int)(self.frame.size.height - ballDiameter - 140)));
    
    rollingBall.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:ballDiameter / 2];
    rollingBall.physicsBody.dynamic = YES;
    rollingBall.physicsBody.categoryBitMask    = index << 2 | ballCategory;
    rollingBall.physicsBody.contactTestBitMask = holeCategory;
    rollingBall.physicsBody.collisionBitMask   = holeCategory | ballCategory;
    
    return rollingBall;
}

/*
 * Returns a new post, to be added to the scene
 * We use the index to keep track of what color the post is
 */
- (SKShapeNode *)newPostOfSuccessWithIndex:(int)index {
    SKShapeNode *postOfSuccess = [[SKShapeNode alloc] init];
    
    CGMutablePathRef myPath = CGPathCreateMutable();
    CGPathAddArc(myPath, NULL, 0, 0, postDiameter / 2, 0, M_PI*2, YES);
    postOfSuccess.path = myPath;
    CGPathRelease(myPath);
    
    postOfSuccess.fillColor = [[self colors][index - 1] colorWithAlphaComponent:0.43f];
    postOfSuccess.lineWidth = 0.2;
    postOfSuccess.glowWidth = 0.5;
    
    postOfSuccess.name = @"postOfSuccess";
    
    postOfSuccess.position = [self getRandomPoint];
    
    postOfSuccess.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:postDiameter / 2];
    postOfSuccess.physicsBody.dynamic = NO;
    postOfSuccess.physicsBody.categoryBitMask    = index << 2 | holeCategory;
    postOfSuccess.physicsBody.contactTestBitMask = ballCategory;
    postOfSuccess.physicsBody.collisionBitMask   = holeCategory | ballCategory;
    
    return postOfSuccess;
}

/*
 * Triggered every time a contact is detected
 */
- (void)didBeginContact:(SKPhysicsContact *)contact {
    int32_t a = contact.bodyA.categoryBitMask;
    int32_t b = contact.bodyB.categoryBitMask;
    
    // edges have value -1 - Check that neither was an edge
    if (a > 0 && b > 0) {
        // Only one ball and one post will have the same index
        // Remember that we left shifted the index two bits; right shift two bits here
        int32_t aColorCategory = a >> 2;
        int32_t bColorCategory = b >> 2;
        int32_t colorIndex = 0x1 << (aColorCategory - 1);
        
        if (aColorCategory == bColorCategory && !(self.colorCategories & colorIndex)) {
            SKShapeNode *ball, *post;
            
            if ([self.gameManager playSound]) {
                [self runAction:[SKAction playSoundFileNamed:@"ballTap.wav" waitForCompletion:NO]];
            }
            
            if ([self.gameManager playVibration]) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            }
            
            if (a & ballCategory) {
                // a is ball
                ball = (SKShapeNode *)contact.bodyA.node;
                post = (SKShapeNode *)contact.bodyB.node;
            } else {
                ball = (SKShapeNode *)contact.bodyB.node;
                post = (SKShapeNode *)contact.bodyA.node;
            }
            
            // Set Color Category Done
            self.colorCategories = self.colorCategories | colorIndex;
            post.fillColor = ball.fillColor;
            if ([self.difficulty isEqualToString:EASY]) {
                [ball setPath:nil];
                [ball removeFromParent];
            }
            self.ballsRemaining--;
            [self setScore:(self.score + 1000)];
            
            if (self.ballsRemaining <= 0) {
                
                // Level can't be greater than 8; program will crash
                if (self.level < 8) {
                    
                    // The faster they solve the level, the more points they get
                    [self setScore:(self.score + (100 * self.timeRemaining))];
                    
                    // Get new level
                    self.level++;
                    [self setupLevel];
                    
                } else {
                    // if they got a new high score, we don't want to give them the "you win" message.
                    if (!self.gameManager.hasNewHighScore) {
                        [self.gameManager setGameOverCode:WIN];
                    }
                    [self.scene.view presentScene:[RBGameOverScene sceneWithSize:self.size] transition:[self reveal]];
                }
            }
        } else if ([self.difficulty isEqualToString:HARD]     &&
                   ((a & holeCategory) || (b & holeCategory)) &&
                   aColorCategory != bColorCategory
                   ) {
            [self.gameManager setGameOverCode:DIED];
            [self.scene.view presentScene:[RBGameOverScene sceneWithSize:self.size] transition:[self reveal]];
        }
    }
}

/*
 * What happens every frame update
 */
-(void)update:(CFTimeInterval)currentTime {
    if (self.timeRemaining > 0) {
        CMAttitude *attitude = self.motionManager.deviceMotion.attitude;
        CGVector myVector = CGVectorMake(attitude.roll  * 10, attitude.pitch * -10);
    
        [self enumerateChildNodesWithName:@"rollingBall" usingBlock:^(SKNode *node, BOOL *stop){
            [node.physicsBody applyForce:myVector];
        }];
    } else {
        [self endTimer];
        [self.gameManager setGameOverCode:TIMEOUT];
        [self.tracker logAction:self.difficultyLevelString category:@"timeOut"];
        [self.scene.view presentScene:[RBGameOverScene sceneWithSize:self.size]];
    }
}

/*
 * Keep track of the time
 * Notice the timer pattern we're using:
 * The timer is set to timeInterval in self setupLevel; we track timeRemaining separately
 * On each tick of timeInterval, we will update timeRemaining and update the time display
 */
-(void)countdownTimer:(id)sender {
    [self setTimeRemaining:self.levelEndTime - CFAbsoluteTimeGetCurrent()];
}

#pragma mark - pauseScreen

/*
 * Displays pause scren
 */
-(void)displayPauseScreen {
    CGSize size = CGSizeMake(200, 300);
    int xCenter = self.size.width / 2;
    int yCenter = ((self.size.height - (topMargin + bottomMargin)) / 2) + bottomMargin;
    CGPoint center = CGPointMake(xCenter, yCenter);
    
    SKColor *black = [SKColor blackColor];
    
    SKSpriteNode *canvas = [self rectangleAt:center size:size name:@"canvas" color:[SKColor colorWithRed:1 green:1 blue:0.8 alpha:1]];
    [canvas setZPosition:1];
    [self addChild:canvas];
    
    [canvas addChild:[self ballAt:CGPointMake(0,   -70) size:40 name:@"ball"]];
    [canvas addChild:[self labelAt:CGPointMake(0, -120) text:@"rolling ball"  fontSize:22 name:@"" color:black]];
    [canvas addChild:[self labelAt:CGPointMake(0,   88) text:@"paused"        fontSize:30 name:@"" color:black]];
    [canvas addChild:[self labelAt:CGPointMake(0,   58) text:@"tap to resume" fontSize:20 name:@"" color:black]];
    [canvas addChild:[self buttonAt:CGPointMake(0,   0) text:@"return to home" name:@"home"]];
}

/*
 *
 */
- (void)displayInstructions {
    CGSize size = CGSizeMake(200, 300);
    int xCenter = self.size.width / 2;
    int yCenter = ((self.size.height - (topMargin + bottomMargin)) / 2) + bottomMargin;
    CGPoint center = CGPointMake(xCenter, yCenter);
    
    SKColor *black = [SKColor blackColor];
    
    SKSpriteNode *c = [self rectangleAt:center size:size name:@"instructions" color:[SKColor colorWithRed:1 green:1 blue:0.8 alpha:1]];
    [c setZPosition:1];
    [self addChild:c];
    
    [c addChild:[self ballAt:CGPointMake(0,   -70) size:40 name:@"ball"]];
    [c addChild:[self labelAt:CGPointMake(0, -120) text:@"rolling ball" fontSize:22 name:@"" color:black]];
    [c addChild:[self labelAt:CGPointMake(0, 113) text:@"tilt your device and" fontSize:18 name:@"" color:black]];
    [c addChild:[self labelAt:CGPointMake(0, 88) text:@"match all the colors" fontSize:18 name:@"" color:black]];
    [c addChild:[self labelAt:CGPointMake(0, 63) text:@"before time runs out" fontSize:18 name:@"" color:black]];
    
    if ([self.difficulty isEqualToString:HARD]) {
        [c addChild:[self labelAt:CGPointMake(0, 30) text:@"get the right colors" fontSize:18 name:@"" color:black]];
        [c addChild:[self labelAt:CGPointMake(0, 5) text:@"or else it's game over!" fontSize:18 name:@"" color:black]];
        [c addChild:[self labelAt:CGPointMake(0, -30) text:@"tap to play" fontSize:24 name:@"" color:black]];
    } else {
        [c addChild:[self labelAt:CGPointMake(0, 0) text:@"tap to play" fontSize:24 name:@"" color:black]];
    }
}

#pragma mark - boxes

/*
 * Put score box up top, with all other labels etc
 */
-(void)setupScoreBox {
    int height      = scoreBoxHeight;
    int screenWidth = self.size.width;
    int xPos        = screenWidth / 2;
    int yPos        = self.size.height - height/2 - 20;
    SKColor *white  = [SKColor whiteColor];
    SKColor *gray   = [SKColor darkGrayColor];
    
    // Populate Box - Layout Constants (all relative to center of scoreBox)
    // bd = ball diameter; c = column; r = row; fs = fontSize
    int c1 = -110;
    int c2 =   50;
    int c3 =  120;
    int r1 =   14;
    int r2 =   -3;
    int r3 =  -28;
    int fs =   17;
    
    // Tilt your device and match the colors
    // Tap anywhere to start playing
    
    SKSpriteNode *sb = [self rectangleAt:CGPointMake(xPos, yPos) size:CGSizeMake(screenWidth, height)
                                    name:@"scoreBox" color:gray];
    [self addChild:sb];

    [sb addChild:[self labelAt:CGPointMake(c1, r2) text:@""      fontSize:fs name:@"difficulty"    color:white]];
    [sb addChild:[self labelAt:CGPointMake(c1, r1) text:@""      fontSize:fs name:@"level"         color:white]];
    [sb addChild:[self labelAt:CGPointMake(c2, r1) text:@""      fontSize:fs name:@"timeRemaining" color:white]];
    [sb addChild:[self labelAt:CGPointMake(c2, r2) text:@"time"  fontSize:fs name:@""              color:white]];
    [sb addChild:[self labelAt:CGPointMake(c3, r1) text:@""      fontSize:fs name:@"score"         color:white]];
    [sb addChild:[self labelAt:CGPointMake(c3, r2) text:@"score" fontSize:fs name:@""              color:white]];
    
    NSString *highScore = [NSString stringWithFormat:@"high score: %05u", [self.gameManager highScore]];
    [sb addChild:[self labelAt:CGPointMake(0, r3) text:highScore fontSize:fs name:@"highScore"     color:white]];
}

/*
 * Give a box outlining the margin, in case iAds don't load properly
 */
-(void)setupBottomBox {
    int xCenter = self.size.width / 2;
    int yPos = bottomMargin / 2;
    [self addChild:[self rectangleAt:CGPointMake(xCenter, yPos) size:CGSizeMake(self.size.width, bottomMargin)
                                name:@"bottomBox" color:[SKColor darkGrayColor]]];
}

#pragma mark - postOrigins

/*
 * Define our "pidgeonholes" in which to place the balls
 * Remember - the point is to keep posts far enough away from each other that balls don't get stuck
 */
- (void)setupPostOrigins {
    int height = self.size.height - topMargin - bottomMargin - 20;
    int width  = self.size.width - 5;
    
    // Something doesn't feel right about these - but not sure what
    [self setSubdivisionWidth:(width  - (4 * ballDiameter) - (3 * postDiameter)) / 3];
    [self setSubdivisionHeight:(height - (4 * ballDiameter) - (3 * postDiameter)) / 3];
    
    // Set this up
    self.postOrigins = [[NSMutableArray alloc] init];
}

/*
 * We remove a post origin from self.postOrigins, each time one is used
 * So, each time we set up a level - wipe out the array and rebuild!
 */
- (void)populatePostOrigins {
    if ([self.postOrigins count] > 0) {
        [self.postOrigins removeAllObjects];
    }
    
    CGFloat rectMargin = ballDiameter + postDiameter;
    CGFloat minX       = ballDiameter + (postDiameter / 2) + 2;
    CGFloat minY       = minX + bottomMargin;
    
    CGFloat spaceBetweenOriginXValues = self.subdivisionWidth + rectMargin;
    CGFloat spaceBetweenOriginYValues = self.subdivisionHeight + rectMargin;
    
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            CGPoint point = CGPointMake(minX + i * spaceBetweenOriginXValues,
                                        minY + j * spaceBetweenOriginYValues);
            
            NSValue *pointValue = [NSValue valueWithCGPoint:point];
            
            [self.postOrigins addObject:pointValue];
        }
    }
}

/*
 * Gives us a randomPoint from self.postOrigins
 * Technically the way it works is that postOrigins is an array of points
 * in getRandomPoint, we get a random point and add it to a random origin from postOrigins
 */
- (CGPoint)getRandomPoint {
    int randomIndex      = arc4random() & [self.postOrigins count] - 1;
    
    CGPoint randomOrigin = [[self.postOrigins objectAtIndex:randomIndex] CGPointValue];
    CGPoint randomPoint  = CGPointMake(randomOrigin.x + (arc4random() % self.subdivisionWidth),
                                       randomOrigin.y + (arc4random() % self.subdivisionHeight));
    // Make sure we can't choose this point again
    [self.postOrigins removeObjectAtIndex:randomIndex];
    
    return randomPoint;
}

/*
 * notice the timer is set to timeInterval - this is why we keep track of self.timeRemaining
 * each tick of timeInterval, we will update timeRemaining and update the time display
 * see "countdownTimer"*
 */
- (void)startTimer {
    [self setLevelEndTime:CFAbsoluteTimeGetCurrent() + self.timeRemaining];
    [self setTimer:[NSTimer scheduledTimerWithTimeInterval:timeInterval target:self
                                                  selector:@selector(countdownTimer:) userInfo:nil
                                                   repeats:YES]];
}

/*
 *
 */
- (void)endTimer {
    if (self.timer != nil) {
        [self.timer invalidate];
        [self setTimer:nil];
    }
}

- (void)clearPostsAndBalls {
    [self enumerateChildNodesWithName:@"rollingBall" usingBlock:^(SKNode *node, BOOL *stop){
        SKShapeNode *shapeNode = (SKShapeNode *)node;
        // Set path to nil before we remove the object
        // this prevents memory leaks, which shapenode is NOTORIOUS for
        [shapeNode setPath:nil];
        [node removeFromParent];
    }];
    
    [self enumerateChildNodesWithName:@"postOfSuccess" usingBlock:^(SKNode *node, BOOL *stop){
        SKShapeNode *shapeNode = (SKShapeNode *)node;
        // Set path to nil before we remove the object
        // this prevents memory leaks, which shapenode is NOTORIOUS for
        [shapeNode setPath:nil];
        [node removeFromParent];
    }];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"adBannerTapped" object:nil];
}

@end