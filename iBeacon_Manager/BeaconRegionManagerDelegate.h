//
//  BeaconRegionManagerDelegate.h
//  iBeacon_Manager
//
//  Created by David Crow on 4/14/14.
//  Copyright (c) 2014 David Crow. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BeaconRegionManagerDelegate <NSObject>

//purpose of creating the delegate is to have a clean way of interacting with the root views.
//Currently you're relying on notifications and a few other things
// This will be useful in implementing callbacks from success blocks from http requests
//instead of using some kind of notifications bullshit

@optional

- (void)beaconRegionManagerDidRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region;


//views need to know the following info
// when a remote plist is done loading, when each type of http request returns (and the list themselves)
-(void)localListFinishedLoadingWithList:(NSArray *)localBeaconList;
-(void)hostedListFinishedLoadingWithList:(NSArray *)hostedBeaconList;
-(void)locationBasedListFinishedLoadingWithList:(NSArray *)loactionBasedBeaconList;




@end

