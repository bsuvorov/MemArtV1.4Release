//
//  HelloCreatorAppDelegate.m
//  ContentCreator
//
//  Created by Boris on 3/15/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "dlLog.h"
#import "HelloCreatorAppDelegate.h"
#import <Parse/Parse.h>
#import "FlurryAnalytics.h"
#import "FlurryAppCircle.h"
#import "globalDefines.h"
#import "TapjoyConnect.h"

@implementation HelloCreatorAppDelegate

@synthesize window;
@synthesize rootViewController;

@synthesize imagePickerController = _imagePickerController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    [FlurryAppCircle setAppCircleEnabled:YES];
    [FlurryAnalytics startSession:@"T45JT89HE2QJ48LMNDE9"];
    [TapjoyConnect requestTapjoyConnect:@"89cc58b9-1410-4a0f-a7e4-de0a90956dca" secretKey:@"TabZH26MZIG7USDDsjJz"];
    
    [Parse setApplicationId:@"UaVgFPbhrQ9yUJp0QFOoeJ862BDUOiOcxVhSN2XJ" 
                  clientKey:@"gJYPk7eCsjXiCbNV6B3KHvkozQBBz2X9azHrkZrN"];

    [PFFacebookUtils initializeWithApplicationId:@"177418532387897"];

    // Register for push notifications
    [application registerForRemoteNotificationTypes:
        UIRemoteNotificationTypeBadge |
        UIRemoteNotificationTypeAlert |
        UIRemoteNotificationTypeSound];
    
    // [[UITabBar appearance] setTintColor:UICOLOR_MEMART];    
    // [[UIToolbar appearance] setTintColor:UICOLOR_MEMART];
    // [[UISlider appearance] setMaximumTrackTintColor:UICOLOR_MEMART];
    [[UISlider appearance] setMinimumTrackTintColor:UICOLOR_MEMART];
    [[UIProgressView appearance] setProgressTintColor:UICOLOR_MEMART];
    
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    
    // Override point for customization after application launch.
    return YES;
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    dlLogInfo(@"My Device Token: %@", deviceToken);
    
    // Tell Parse about the device token
    [PFPush storeDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application 
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    if ([error code] == 3010) {
        dlLogWarn(@"Push notifications don't work in the simulator!");
    } else {
        dlLogWarn(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (void)application:(UIApplication *)application 
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    dlLogInfo(@"Received remote push notification");
    for (NSString *key in userInfo) {
        dlLogInfo(@"%@=%@", key, [userInfo objectForKey:key]);
    }
        
    [PFPush handlePush:userInfo];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [PFFacebookUtils handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [PFFacebookUtils handleOpenURL:url]; 
}

void uncaughtExceptionHandler(NSException *exception)
{
    dlLogCrit(@"Uncaught Exception - Application Crashed!");
    [FlurryAnalytics logError:@"Uncaught Exception" message:@"Application Crashing" exception:exception];
    return;
}

@end
