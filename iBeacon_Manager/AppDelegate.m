//
//  AppDelegate.m
//  UABeacons
//
//  Created by David Crow on 9/26/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "AppDelegate.h"
#import "UAirship.h"
#import "UAConfig.h"
#import "UAPush.h"
#import "UALocationService.h"
#import "BeaconRegionManager.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{


    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    UA_LDEBUG(@"Application did become active.");

}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    UA_LINFO(@"APNS device token: %@", deviceToken);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *) error
{
    UA_LERR(@"Failed To Register For Remote Notifications With Error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    
    UA_LINFO(@"Received remote notification: %@", userInfo);
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
		// Stop normal location updates and start significant location change updates for battery efficiency.
//		[viewController.locationManager startUpdatingLocation];
//		[viewController.locationManager startMonitoringSignificantLocationChanges];
	}
	else {
		NSLog(@"Significant location change monitoring is not available.");
	}
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    // If the application is in the foreground, we will notify the user of the region's state via an alert.
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:notification.alertBody message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //[alert show];
}

@end
