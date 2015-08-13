//
//  RBHomeScene.m
//  RollingBall
//
//  Home scene - gives the ability to start a game, submit feedback, and other things
//
//  Created by peter on 7/12/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import "RBHomeScene.h"
#import "RBGameScene.h"
#import "RBOptionsScene.h"
#import "RBRemoveAdsScene.h"
#import <MessageUI/MessageUI.h>

@implementation RBHomeScene

/*
 * Initialize a new home screen
 */
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        [[self tracker] setCurrentSceneName:@"HomeScene"];
        
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
    if ([node isKindOfClass:[SKLabelNode class]]) {
        button = (SKSpriteNode *)[node parent];
    } else {
        button = node;
    }
    
    // Set buttons to gray on touch, set to white on release, to give feedback to user
    SKColor *gray = [SKColor grayColor];
    if ([node.name isEqualToString:@"play"]      ||
        [node.name isEqualToString:@"options"]   ||
        [node.name isEqualToString:@"removeAds"] ||
        [node.name isEqualToString:@"share"]     ||
        [node.name isEqualToString:@"feedback"]
        ){
        [button setColor:gray];
        [self.tracker logAction:node.name category:@"touch"];
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
    
    if ([node.name isEqualToString:@"play"]      ||
        [node.name isEqualToString:@"options"]   ||
        [node.name isEqualToString:@"removeAds"] ||
        [node.name isEqualToString:@"share"]     ||
        [node.name isEqualToString:@"feedback"]
        ){
        [button setColor:[SKColor grayColor]];
    } else {
        SKColor *white = [SKColor whiteColor];
        [(SKSpriteNode *)[self childNodeWithName:@"play"]      setColor:white];
        [(SKSpriteNode *)[self childNodeWithName:@"options"]   setColor:white];
        [(SKSpriteNode *)[self childNodeWithName:@"removeAds"] setColor:white];
        [(SKSpriteNode *)[self childNodeWithName:@"share"]     setColor:white];
        [(SKSpriteNode *)[self childNodeWithName:@"feedback"]  setColor:white];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch     = [touches anyObject];
    CGPoint location   = [touch locationInNode:self];
    SKSpriteNode *node = (SKSpriteNode *)[self nodeAtPoint:location];
    
    SKSpriteNode *button;
    if ([node isKindOfClass:[SKLabelNode class]]) {
        button = (SKSpriteNode *)[node parent];
    } else {
        button = node;
    }
    
    SKColor *white = [SKColor whiteColor];
    if ([node.name isEqualToString:@"play"]) {
        [button setColor:white];
        [self.scene.view presentScene:[RBGameScene sceneWithSize:self.size] transition:[self reveal]];
    }
    if ([node.name isEqualToString:@"options"]) {
        [button setColor:white];
        [self.scene.view presentScene:[RBOptionsScene sceneWithSize:self.size] transition:[self reveal]];
    }
    if ([node.name isEqualToString:@"share"]) {
        [button setColor:white];
        [self shareWithFriends];
    }
    if ([node.name isEqualToString:@"removeAds"]) {
        [button setColor:white];
        [self.scene.view presentScene:[RBRemoveAdsScene sceneWithSize:self.size] transition:[self reveal]];
    }
    if ([node.name isEqualToString:@"feedback"]) {
        [button setColor:white];
        [self submitFeedback];
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
    int r7 = r6 - m;
    int r8 = r7 - m - 10;

    SKColor *black = [SKColor blackColor];

    [self addChild:[self ballAt:  CGPointMake(x, r1) size:48 name:@""]];
    [self addChild:[self labelAt: CGPointMake(x, r2) text:@"rolling ball"        fontSize:33 name:@"" color:black]];
    [self addChild:[self buttonAt:CGPointMake(x, y)  text:@"start game"          name:@"play"      ]];
    [self addChild:[self buttonAt:CGPointMake(x, r4) text:@"options"             name:@"options"   ]];
    [self addChild:[self buttonAt:CGPointMake(x, r5) text:@"get more time"       name:@"removeAds" ]];
    [self addChild:[self buttonAt:CGPointMake(x, r6) text:@"share with friend"   name:@"share"     ]];
    [self addChild:[self buttonAt:CGPointMake(x, r7) text:@"submit feedback"     name:@"feedback"  ]];
    [self addChild:[self labelAt: CGPointMake(x, r8) text:@"© 2014 peter lebrun" fontSize:22 name:@"" color:black]];
}

/*
 * Opens email interface to send feedback
 */
- (void)submitFeedback {
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    [mailController setMailComposeDelegate:self];

    [mailController setMessageBody:@"Message" isHTML:NO];
    [mailController setToRecipients:@[@"rollingballfeedback@gmail.com"]];
    [mailController setSubject:@"rolling ball feedback"];
    [mailController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [self.view.window.rootViewController presentViewController:mailController animated:YES completion:nil];
}

/*
 * Closes the email interface after it dismisses
 */
- (void)mailComposeController:(MFMailComposeViewController *)mailController
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {

    [mailController dismissViewControllerAnimated:YES completion:nil];
    [(SKSpriteNode *)[self childNodeWithName:@"feedback"] setColor:[SKColor whiteColor]];
}

/*
 * Send to friend via text message
 */
- (void)shareWithFriends {
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:@[]];
    [messageController setBody:[NSString stringWithFormat:@"Check out rolling ball - it's great fun!  itms-apps://itunes.com/apps/rolling-ball"]];
    
    // Present message view controller on screen
    [self.view.window.rootViewController presentViewController:messageController animated:YES completion:nil];
}

/*
 * Get rid of message send
 */
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult) result {
    
    switch (result) {
        case MessageComposeResultCancelled:
            // Log successful send
            break;
            
        case MessageComposeResultFailed: {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            // Log successful send
            break;
            
        default:
            // I wonder how we would get here
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
    [(SKSpriteNode *)[self childNodeWithName:@"share"] setColor:[SKColor whiteColor]];
}

@end