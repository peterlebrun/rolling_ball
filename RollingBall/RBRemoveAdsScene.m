//
//  RBRemoveAdsScene.m
//  RollingBall
//
//  Created by peter on 8/8/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import "RBHomeScene.h"
#import "RBRemoveAdsScene.h"

@interface RBRemoveAdsScene ()

/*
 * Product IDs
 */
@property NSString *removeAdsID;
@property NSString *moreTimeID;
@property NSString *goProID;
@property NSSet *productIDs;

/*
 * Products
 */
@property (strong, nonatomic) SKProduct *removeAdsProduct;
@property (strong, nonatomic) SKProduct *moreTimeProduct;
@property (strong, nonatomic) SKProduct *goProProduct;

/* Color
 */
@property SKColor *gray70;

@end

@implementation RBRemoveAdsScene

@synthesize removeAdsID;
@synthesize moreTimeID;
@synthesize goProID;

@synthesize productIDs;

@synthesize removeAdsProduct;
@synthesize moreTimeProduct;
@synthesize goProProduct;

@synthesize gray70;

- (NSString *)removeAdsID {
    if (!removeAdsID) {
        removeAdsID = @"rolling_ball_remove_ads";
    }
    return removeAdsID;
}

- (NSString *)moreTimeID {
    if (!moreTimeID) {
        moreTimeID = @"rolling_ball_more_time";
    }
    return moreTimeID;
}

- (NSString *)goProID {
    if (!goProID) {
        goProID = @"rolling_ball_go_pro";
    }
    return goProID;
}

- (NSSet *)productIDs {
    if (!productIDs) {
        productIDs = [NSSet setWithObjects: [self removeAdsID], [self moreTimeID], [self goProID], nil];
    }
    return productIDs;
}

- (SKColor *)gray70 {
    if (!gray70) {
        gray70 = [SKColor colorWithWhite:0.80 alpha:0.9];
    }
    return gray70;
}

/*
 * Initialize a new home screen
 */
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        [[self tracker] setCurrentSceneName:@"RemoveAdsScene"];
        [self.tracker logAction:@"enterScreen" category:@"touch"];
        
        [self setBackgroundColor:[SKColor colorWithRed:1 green:1 blue:0.8 alpha:1]];
        
        [self setupScreen];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle:)
                                                     name:@"disableRemoveAdsButton" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle:)
                                                     name:@"disableMoreTimeButton" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle:)
                                                     name:@"disableGoProButton" object:nil];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        // Call setup screen frm skProductsRequest functions
        if ([SKPaymentQueue canMakePayments]) {
            SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[self productIDs]];
            request.delegate = self;
            [request start];
        }
    }
    return self;
}

//Handle Notification
- (void)handle:(NSNotification *)notification {
    NSString *nodeName;
    
    if ([notification.name isEqualToString:@"disableMoreTimeButton"]) {
        nodeName = @"moreTime";
        SKSpriteNode *button = (SKSpriteNode *)[self childNodeWithName:nodeName];
        SKLabelNode  *label = (SKLabelNode *)[button childNodeWithName:nodeName];
        [button setColor:[self gray70]];
        [label setText:@"got it!"];
    }
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
    if (([node.name isEqualToString:@"moreTime"]  && ![self.gameManager hasPaidForMoreTime]) ||
         [node.name isEqualToString:@"restore"]   ||
         [node.name isEqualToString:@"home"]
        ){
        [button setColor:[SKColor grayColor]];
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
    
    if (([node.name isEqualToString:@"moreTime"]  && ![self.gameManager hasPaidForMoreTime]) ||
         [node.name isEqualToString:@"restore"]   ||
         [node.name isEqualToString:@"home"]
        ){
        [button setColor:[SKColor whiteColor]];
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
    if ([node.name isEqualToString:@"moreTime"] && [self moreTimeProduct]) {
        [button setColor:white];
        [(SKLabelNode *)[self childNodeWithName:@"loading"] setText:@"processing..."];
        [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:[self moreTimeProduct]]];
    }
    if ([node.name isEqualToString:@"restore"]) {
        [button setColor:white];
        [(SKLabelNode *)[self childNodeWithName:@"loading"] setText:@"processing..."];
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
    if ([node.name isEqualToString:@"home"]) {
        [button setColor:white];
        [self.scene.view presentScene:[RBHomeScene sceneWithSize:self.size] transition:[self reveal]];
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
    int r6 = r5 - (1.15 * m);
/*    int r7 = r6 - m;
    int r8 = r7 - (1.15 * m);*/
    
    SKColor *black = [SKColor blackColor];

    [self addChild:[self ballAt:  CGPointMake(x, r1) size:48 name:@""]];
    [self addChild:[self labelAt: CGPointMake(x, r2) text:@"rolling ball" fontSize:33 name:@"" color:black]];
    [self addChild:[self buttonAt:CGPointMake(x, y) text:@"get more time"      name:@"moreTime"]];
    [(SKSpriteNode *)[self childNodeWithName:@"moreTime"] setColor:[self gray70]];
    [self addChild:[self buttonAt:CGPointMake(x, r4) text:@"restore purchases" name:@"restore"]];
    [self addChild:[self buttonAt:CGPointMake(x, r5) text:@"return to home" name:@"home"]];
    [self addChild:[self labelAt:CGPointMake(x, r6) text:@"loading..." fontSize:33 name:@"loading" color:black]];
}

#pragma mark - SKProductsRequestDelegate

-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if ([self.scene isKindOfClass:[RBRemoveAdsScene class]]) {
        BOOL gotIt = NO;
        NSString *nodeName;
    
        for (SKProduct *product in response.products) {
            if ([product.productIdentifier isEqualToString:[self moreTimeID]]) {
                gotIt = [self.gameManager hasPaidForMoreTime];
                if (!gotIt) {
                    [self setMoreTimeProduct:product];
                }
                nodeName = @"moreTime";
            }

            SKSpriteNode *button = (SKSpriteNode *)[self childNodeWithName:nodeName];
            SKLabelNode  *label = (SKLabelNode *)[button childNodeWithName:nodeName];
            NSString *labelText;
            SKColor *color;
        
            if (gotIt) {
                labelText = @"already got it!";
                color = [self gray70];
            } else {
                labelText = [NSString stringWithFormat:@"%@: %@", product.localizedTitle, product.price];
                color = [SKColor whiteColor];
            }
            [label setText:labelText];
            [button setColor:color];
        }
    
        for (SKProduct *invalidProduct in response.invalidProductIdentifiers) {
            NSLog(@"Product not found: %@", invalidProduct);
        }
 
        [(SKLabelNode *)[self childNodeWithName:@"loading"] setText:@""];
    }
}

#pragma mark - SKPaymentTransactionObserver

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions)
    {
        NSString *TxID = transaction.payment.productIdentifier;
        
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateRestored: {
                
                // setHasPaidTo.. disables buttons via calls to NSNotificationCenter through gameManager
                // Not ideal in terms of clarity, but it will provide a consistent user experience
                // See method definitions in RBGameManager for more information
                if ([TxID isEqualToString:[self moreTimeID]]) {
                    [self.gameManager setHasPaidForMoreTime:YES];
                }
                
                [(SKLabelNode *)[self childNodeWithName:@"loading"] setText:@"success!"];
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                break;
            }
                
            case SKPaymentTransactionStateFailed:
                [(SKLabelNode *)[self childNodeWithName:@"loading"] setText:@"please try again"];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            default:
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    if (![[(SKLabelNode *)[self childNodeWithName:@"loading"] text] isEqualToString:@"success!"]) {
        [(SKLabelNode *)[self childNodeWithName:@"loading"] setText:@"nothing to restore"];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {        [(SKLabelNode *)[self childNodeWithName:@"loading"] setText:@"please try again"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"disableRemoveAdsButton" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"disableMoreTimeButton" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"disableGoProButton" object:nil];
}
@end