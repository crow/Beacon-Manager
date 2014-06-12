/*
 Copyright 2009-2013 Urban Airship Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#import "PreferencesTableViewController.h"
#import "BeaconManagerValues.h"

#import "UAirship.h"
#import "UAUser.h"
#import "UAPush.h"
#import "UALocationService.h"
#import "BeaconRegionManager.h"


@interface PreferencesTableViewController ()

@property (nonatomic, strong) CBCentralManager *bleManager;


- (IBAction)pushToggled:(id)sender;

@end

@implementation PreferencesTableViewController

- (void)dealloc {
    self.bleManager.delegate = nil;
}

- (void)viewDidLoad {
    NSString *buildNumber = (NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    if ([buildNumber length] == 0) {
        buildNumber = @"Dev Build";
    }
    self.appVersionValue.text = [NSString stringWithFormat:@"%@ (%@)",
                ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"Unknown Version"),
                buildNumber];
    self.sdkVersionValue.text = [UAirshipVersion get];
    self.userIDValue.text = [UAUser defaultUser].username ?: @"Unavailable";
    self.channelIDValue.text = @"Unavailable";
    self.deviceTokenValue.text = [UAPush shared].deviceToken ?: @"Unavailable";

    //Initializes the CBCentralManager to montitor changes in bluetooth state (via the control center, etc)
    [self checkBluetoothState];

    self.pushEnabledSwitch.on = [UAPush shared].pushEnabled;
    self.soundEnabledSwitch.enabled = self.pushEnabledSwitch.on;//disable the sound toggle if push is disabled
    self.soundEnabledSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:kSoundEnabled];

    self.locationEnabledSwitch.on = [UALocationService airshipLocationServiceEnabled];

}

- (void)viewWillDisappear:(BOOL)animated {
    [UAPush shared].pushEnabled = self.pushEnabledSwitch.on;
    [UALocationService setAirshipLocationServiceEnabled:self.locationEnabledSwitch.on];

    // Do trigger this registration *after* push is turned on or off, as it will just do a local APNS
    // registration and trigger the duplicate registration check, so we only do one trip to the server
    // if push is enabled.
    
    // sound - toggle on or off
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.soundEnabledSwitch.on != [defaults boolForKey:kSoundEnabled]) {
        [defaults setBool:self.soundEnabledSwitch.on forKey:kSoundEnabled];

        // Re-Register for remote notification types with the updated change
        UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge;

        if ([defaults boolForKey:kSoundEnabled]) {
            notificationTypes |= UIRemoteNotificationTypeSound;
        }

        [[UAPush shared] registerForRemoteNotificationTypes:notificationTypes];
    }
}

#pragma mark -
#pragma mark IB Actions

- (IBAction)pushToggled:(id)sender {
    self.soundEnabledSwitch.enabled = self.pushEnabledSwitch.on;
}

#pragma mark -
#pragma mark Bluetooth Capability Checks

- (void)checkBluetoothState {
    // CBCentralManager crashes in the simulator on dealloc, so avoid this through some terrible code
    if (!self.bleManager && ([[UIDevice currentDevice].model rangeOfString:@"Simulator"].location == NSNotFound)) {

        if ([self.bleManager respondsToSelector:@selector(initWithDelegate:queue:options:)]) {

            // Put on main queue so we can call UIAlertView from delegate callbacks.
            self.bleManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                   queue:dispatch_get_main_queue()
                                                                 options:@{CBCentralManagerOptionShowPowerAlertKey:[NSNumber numberWithBool:NO]}];
        } else {
            // Put on main queue so we can call UIAlertView from delegate callbacks.
            self.bleManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                   queue:dispatch_get_main_queue()];
        }
    }

    if (self.bleManager) {
        [self centralManagerDidUpdateState:self.bleManager]; // Show initial state
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString *stateString = nil;

    UA_LDEBUG(@"Central BT Manager Updated.");

    if (self.bleManager.state == CBCentralManagerStatePoweredOn){
        [[BeaconRegionManager shared] setBluetoothReady:YES];
    } else {
        switch (self.bleManager.state) {
            case CBCentralManagerStateUnsupported:
                stateString = @"This device does not support Bluetooth Low Energy. iBeacons disabled.";
                [[BeaconRegionManager shared] setBluetoothReady:NO];
                break;
            case CBCentralManagerStateUnauthorized:
                stateString = @"This app is not authorized to use Bluetooth Low Energy. iBeacons disabled.";
                [[BeaconRegionManager shared] setBluetoothReady:NO];
                break;
            case CBCentralManagerStatePoweredOff:
                stateString = @"Bluetooth is currently powered off. To use iBeacons, bluetooth must be enabled.";
                [[BeaconRegionManager shared] setBluetoothReady:NO];
                break;
            case CBCentralManagerStateResetting:
                stateString = @"Bluetooth is currently resetting, iBeacon functionality will be available momentarily";
                [[BeaconRegionManager shared] setBluetoothReady:NO];
                break;
            default:
                //when state is unknown assume ready
                [[BeaconRegionManager shared] setBluetoothReady:YES];
                break;
        }

        if (![[BeaconRegionManager shared] bluetoothReady]) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Bluetooth Error" message:stateString delegate:self
                                  cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
}

@end
