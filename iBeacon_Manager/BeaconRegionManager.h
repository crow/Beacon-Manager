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

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; \

@interface BeaconRegionManager : NSObject <CLLocationManagerDelegate>


@property  (nonatomic, assign) BOOL ibeaconsEnabled;

//plist manager for managing local (sample) and remotely hosted plists
@property (strong, nonatomic, readonly) PlistManager *plistManager;
//ranged beacons from didRangeBeacons callback
@property (strong, nonatomic, readonly) NSArray *rangedBeacons;
//detailed ranged dictionary ordered by zone (unknown, immediate, near, far)
@property (strong, nonatomic, readonly) NSDictionary *rangedBeaconsDetailed;
//beacons that are currently monitored (same as available managed beacon regions by default)
@property (strong, nonatomic, readonly) NSSet *monitoredBeaconRegions;
//all the managed regions loaded from the plist manager, data store for the available regions
@property (strong, nonatomic, readonly) NSArray *availableManagedBeaconRegionsList;

//@property (strong, nonatomic) NSMutableDictionary *availableManagedBeaconRegions;

@property (strong, nonatomic) NSMutableDictionary *beaconStats;


+ (id)shared;
-(void)startManager;

//checks state of iBeacons enabled and starts monitoring accordingly
-(void)checkiBeaconsEnabledState;


//beacon and beacon region getters
-(CLBeacon *)beaconWithId:(NSString *)identifier;
-(CLBeaconRegion *)beaconRegionWithId:(NSString *)identifier;


-(void)loadMonitoredRegions;
-(void)loadAvailableRegions;

//monitoring checking
-(BOOL)isMonitored:(CLBeaconRegion *) beaconRegion;
-(void)startMonitoringBeaconInRegion:(CLBeaconRegion *)beaconRegion;
-(void)stopMonitoringBeaconInRegion:(CLBeaconRegion *)beaconRegion;
-(void)startMonitoringAllAvailableBeaconRegions;
-(void)stopMonitoringAllAvailableBeaconRegions;
-(void)stopMonitoringAllBeaconRegions;

//stats getters
-(NSMutableDictionary *)beaconStatsForIdentifier:(NSString *)identifier;
-(double)lastEntryForIdentifier:(NSString *)identifier;
-(double)lastExitForIdentifier:(NSString *)identifier;
-(double)cumulativeTimeForIdentifier:(NSString *)identifier;
//stats mgmt
-(void)clearBeaconStats;


@end
