//
//  UABeaconManager.h
//  UABeacons
//
//  Created by David Crow on 10/3/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "PlistManager.h"
#import "ManagedBeaconRegion.h"

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; \

@interface BeaconRegionManager : NSObject <CLLocationManagerDelegate>

@property (strong, nonatomic, readonly) NSArray *rangedBeacons;
@property (strong, nonatomic, readonly) NSDictionary *rangedBeaconsDetailed;

//The current beacons that are monitored, apple already used "monitoredRegions" so they chose "rangedRegions"
@property (strong, nonatomic, readonly) NSSet *monitoredBeaconRegions;

//Available beacon regions are all the regions loaded from the plist manager
@property (strong, nonatomic, readonly) NSArray *availableManagedBeaconRegions;
@property (strong, nonatomic) ManagedBeaconRegion *currentRegion;//this may be redundant with rangedBeacons



+ (id)shared;
-(void)updateVistedStatsForRegionIdentifier:(NSString *)identifier;
-(ManagedBeaconRegion *)beaconRegionWithId:(NSString *)identifier;
-(CLBeacon *)beaconWithId:(NSString *)identifier;

-(void)updateMonitoredRegions;
-(void)updateAvailableRegions;

-(BOOL)isMonitored:(CLBeaconRegion *) beaconRegion;

-(void)startMonitoringBeaconInRegion:(CLBeaconRegion *)beaconRegion;
-(void)stopMonitoringBeaconInRegion:(CLBeaconRegion *)beaconRegion;
-(void)startMonitoringAllAvailableBeaconRegions;
-(void)stopMonitoringAllAvailableBeaconRegions;

-(CLBeacon *)loadMatchingBeaconForRegion:(ManagedBeaconRegion *) beaconRegion FromBeacons:(NSArray *)beacons;


@end
