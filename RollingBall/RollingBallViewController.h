//
//  RollingBallViewController.h
//  RollingBall
//

//  Copyright (c) 2014 peter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <iAd/iAd.h>

@interface RollingBallViewController : UIViewController <ADBannerViewDelegate>

@property (weak, nonatomic) IBOutlet ADBannerView *adBanner;
@property (weak, nonatomic) IBOutlet UILabel      *lblTimerMessage;

@end
