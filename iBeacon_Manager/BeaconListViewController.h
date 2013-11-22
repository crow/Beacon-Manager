//
//  BeaconListViewController.h
//  iBeacon_Manager
//
//  Created by David Crow on 11/18/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BeaconListViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITextField *beaconListURL;
@property (weak, nonatomic) IBOutlet UITableViewCell *viewAvailableIbeaconsCell;

@end
