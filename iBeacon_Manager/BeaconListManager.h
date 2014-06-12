//
//  BeaconListManager.h
//  iBeacon_Manager
//
//  Created by David Crow on 10/3/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/Corelocation.h>
#import <Foundation/Foundation.h>

@interface BeaconListManager : NSObject <NSURLConnectionDelegate>

@property (nonatomic, copy, readonly) NSArray *availableBeaconRegionsList;

//List loading
-(void)loadLastMonitoredList;
-(void)loadLocalPlist;
-(void)loadSingleBeaconRegion:(CLBeaconRegion * ) beaconRegion;
-(void)loadBeaconRegionsArray:(NSArray *) beaconRegions;


@end
