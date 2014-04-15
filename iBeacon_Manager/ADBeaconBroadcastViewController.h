//
//  BeaconBroadcastViewController.h
//  iBeacon_Manager
//
//  Created by David Crow on 1/20/14.
//  Copyright (c) 2014 David Crow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ADBeaconBroadcastViewController : UITableViewController <CBPeripheralManagerDelegate, UIAlertViewDelegate, UITextFieldDelegate>

@end
