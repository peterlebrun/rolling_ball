//
//  RollingBallViewController.m
//  RollingBall
//
//  Created by peter on 5/3/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import "RollingBallViewController.h"
#import "RBHomeScene.h"
#import "RBGameManager.h"

@interface RollingBallViewController()
@property (nonatomic) RBGameManager *gameManager;
@end

@implementation RollingBallViewController
@synthesize gameManager;

/*
 * Keep game manager accessible throughout all scenes
 */
- (RBGameManager *)gameManager {
    if (!gameManager) {
        [self setGameManager:[RBGameManager sharedInstance]];
    }
    return gameManager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.adBanner.delegate = self;
    self.adBanner.alpha    = 0.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle:) name:@"hideAds"
                                               object:nil];
    
    if ([self.gameManager hasPaidToRemoveAds]) {
        [self.adBanner removeFromSuperview];
    }

    [(SKView *)self.view presentScene:[RBHomeScene sceneWithSize:self.view.bounds.size]];
}

//Handle Notification
- (void)handle:(NSNotification *)notification
{
    if ([notification.name isEqualToString:@"hideAds"]) {
        [[self adBanner] removeFromSuperview];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma Ad Stuff
-(void)bannerViewWillLoadAd:(ADBannerView *)banner
{
    //NSLog(@"Ad banner will load ad.");
}

-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    //NSLog(@"Ad banner did load ad.");
    [UIView animateWithDuration:0.5 animations:^{
        self.adBanner.alpha = 1.0;
    }];
}

-(BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    //NSLog(@"Ad Banner action is aboug to begin");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"adBannerTapped" object:nil];
    return YES;
}

-(void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    //NSLog(@"Ad Banner action did finish");
}

-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    //NSLog(@"Unable to show ads.  Error %@", [error localizedDescription]);
    [UIView animateWithDuration:0.5 animations:^{
        self.adBanner.alpha = 0.0;
    }];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"hideAds" object:nil];
}

@end