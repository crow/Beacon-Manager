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
#import "RegionManager.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    //init UABeaconManager
    [RegionManager shared];
    [PlistManager shared];

    // This prevents the UA Library from registering with UIApplication by default. This will allow
    // you to prompt your users at a later time. This gives your app the opportunity to explain the
    // benefits of push or allows users to turn it on explicitly in a settings screen.
    //
    // If you just want everyone to immediately be prompted for push, you can
    // leave this line out.
    [UAPush setDefaultPushEnabledValue:NO];
    
    // Set log level for debugging config loading (optional)
    // It will be set to the value in the loaded config upon takeOff
    [UAirship setLogLevel:UALogLevelTrace];
    
    // Populate AirshipConfig.plist with your app's info from https://go.urbanairship.com
    // or set runtime properties here.
    UAConfig *config = [UAConfig defaultConfig];
    
    // You can then programatically override the plist values:
    // config.developmentAppKey = @"YourKey";
    // etc.
    
    // Call takeOff (which creates the UAirship singleton)
    [UAirship takeOff:config];
    
    // Print out the application configuration for debugging (optional)
    UA_LDEBUG(@"Config:\n%@", [config description]);
    
    // Set the icon badge to zero on startup (optional)
    
    
    // Set the notification types required for the app (optional). With the default value of push set to no,
    // UAPush will record the desired remote notification types, but not register for
    // push notifications as mentioned above. When push is enabled at a later time, the registration
    // will occur normally. This value defaults to badge, alert and sound, so it's only necessary to
    // set it if you want to add or remove types.
    [UAPush shared].notificationTypes = (UIRemoteNotificationTypeBadge |
                                         UIRemoteNotificationTypeSound |
                                         UIRemoteNotificationTypeAlert);
    
    [[UAPush shared] setAutobadgeEnabled:YES];
    [[UAPush shared] resetBadge];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    UA_LDEBUG(@"Application did become active.");
    
    // Set the icon badge to zero on resume (optional)
    [[UAPush shared] resetBadge];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    UA_LINFO(@"APNS device token: %@", deviceToken);
    
    // Updates the device token and registers the token with UA. This won't occur until
    // push is enabled if the outlined process is followed. This call is required.
    [[UAPush shared] registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *) error {
    UA_LERR(@"Failed To Register For Remote Notifications With Error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    UA_LINFO(@"Received remote notification: %@", userInfo);
    
    
    // Send the alert to UA so that it can be handled and tracked as a direct response. This call
    // is required.
    [[UAPush shared] handleNotification:userInfo applicationState:application.applicationState];
    
    // Reset the badge after a push received (optional)
    [[UAPush shared] resetBadge];
}


- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    // A user can transition in or out of a region while the application is not running.
    // When this happens CoreLocation will launch the application momentarily, call this delegate method
    // and we will let the user know via a local notification.
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    [[RegionManager shared] updateVistedStatsForRegionIdentifier:region.identifier];
    
    if(state == CLRegionStateInside)
    {
        notification.alertBody = [NSString stringWithFormat:@"You're inside the region %@", region.identifier];
    }
    else if(state == CLRegionStateOutside)
    {
        notification.alertBody = [NSString stringWithFormat:@"You're outside the region %@", region.identifier];
    }
    else
    {
        return;
    }
    
    // If the application is in the foreground, it will get a callback to application:didReceiveLocalNotification:.
    // If its not, iOS will display the notification to the user.
    //[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:notification.alertBody message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  //not now, stahp  [alert show];
}

@end
