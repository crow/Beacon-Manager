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
#import "BeaconListManager.h"
#import "BeaconRegionManagerDelegate.h"

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; \

@interface BeaconRegionManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic) BOOL bluetoothReady;

//CoreLocation
@property (nonatomic, strong) CLLocationManager *locationManager;

//CoreBluetooth
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;

//Beacon List manager
@property (strong, nonatomic, readonly) BeaconListManager *listManager;

//Beacon stats dictionary that gets saved in NSUserDefaults
@property (strong, nonatomic) NSMutableDictionary *beaconStats;

//Beacon Manager delegate
@property (nonatomic, assign) id<BeaconRegionManagerDelegate> beaconRegionManagerDelegate;

//Beacon Manager startup
+(id)shared;
-(void)startManager;

//beacon and beacon region getters
-(CLBeacon *)beaconWithId:(NSString *)identifier;
-(CLBeaconRegion *)beaconRegionWithId:(NSString *)identifier;

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
-(int)visitsForIdentifier:(NSString *)identifier;
-(double)averageVisitTimeForIdentifier:(NSString *)identifier;

//stats mgmt
-(void)clearAllBeaconStats;
-(void)clearBeaconStatsForBeaconRegion:(CLBeaconRegion *)beaconRegion;

//exit and entry tag mgmt
-(NSArray *)entryTagsForBeaconRegion:(CLBeaconRegion *)beaconRegion;
-(NSArray *)exitTagsForBeaconRegion:(CLBeaconRegion *)beaconRegion;
-(void)addEntryTagsForBeaconRegion:(CLBeaconRegion *)beaconRegion;
-(void)addExitTagsForBeaconRegion:(CLBeaconRegion *)beaconRegion;
-(void)removeEntryTagsForBeaconRegion:(CLBeaconRegion *)beaconRegion;
-(void)removeExitTagsForBeaconRegion:(CLBeaconRegion *)beaconRegion;


@end
