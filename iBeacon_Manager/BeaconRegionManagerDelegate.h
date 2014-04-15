//
//  BeaconRegionManagerDelegate.h
//  iBeacon_Manager
//
//  Created by David Crow on 4/14/14.
//  Copyright (c) 2014 David Crow. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BeaconRegionManagerDelegate <NSObject>

//This delegate is designed to be implemented a root view controller that's displaying beacon information

@optional

- (void)beaconRegionManagerDidRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region;

// when a remote plist is done loading, when each type of http request returns (and the list themselves)
-(void)localListFinishedLoadingWithList:(NSArray *)localBeaconList;
-(void)hostedListFinishedLoadingWithList:(NSArray *)hostedBeaconList;
-(void)locationBasedListFinishedLoadingWithList:(NSArray *)loactionBasedBeaconList;

@end

