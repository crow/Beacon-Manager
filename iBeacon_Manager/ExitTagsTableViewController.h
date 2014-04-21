//
//  ExitTagsTableViewController.h
//  UA_Beacon_Manager
//
//  Created by David Crow on 4/17/14.
//  Copyright (c) 2014 David Crow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ExitTagsTableViewController : UITableViewController

@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CLBeacon *beacon;

@end
