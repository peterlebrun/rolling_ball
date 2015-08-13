//
//  RollingBallAppDelegate.m
//  RollingBall
//
//  Created by peter on 5/3/14.
//  Copyright (c) 2014 peter. All rights reserved.
//

#import "RollingBallAppDelegate.h"
#import "RBTracker.h"
#import "RBGameManager.h"

@interface RollingBallAppDelegate()

@property (nonatomic) RBGameManager *gameManager;
@property (nonatomic) RBTracker *tracker;

@end

@implementation RollingBallAppDelegate
@synthesize gameManager;
@synthesize tracker;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /*
     * trackUncaughtExceptions – Tracking uncaught exceptions will flag up any exceptions that you are not
     * dealing with that have caused your application to crash.
     */
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    /*
     * logLevel – Google Analytics iOS SDK has 4 logging levels: kGAILogLevelError, kGAILogLevelWarning,
     * kGAILogLevelInfo, and kGAILogLevelVerbose. Verbose logging enables all of the various types of log
     * output and prints it to the console in Xcode. This is extremely useful when you first start using
     * Google Analytics for iOS as it lets you see what is going on under the hood.
     */
    [[GAI sharedInstance].logger setLogLevel:kGAILogLevelVerbose];
    
    /* dispatchInterval – By default, this is set to 120, which states that tracking information should be
     * dispatched (uploaded to Google Analytics) automatically every 120 seconds. In this tutorial you will
     * set this to a shorter time period so that you can see the data in your Google Analytics dashboard
     * without having to wait for a prolonged period of time. In a production environment every 120 seconds
     * should be often enough.
     */
    [GAI sharedInstance].dispatchInterval = 120;
        
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
