//
//  BeaconStatsViewController.h
//  iBeacon_Manager
//
//  Created by David Crow on 11/14/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RegionManager.h"

@interface BeaconStatsViewController : UITableViewController <UIAlertViewDelegate>
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) CLBeacon *beacon;
@end
