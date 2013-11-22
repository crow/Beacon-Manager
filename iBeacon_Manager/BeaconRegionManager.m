//
//  UABeaconManager.m
//  UABeacons
//
//  Created by David Crow on 10/3/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "BeaconRegionManager.h"


@interface BeaconRegionManager ()

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation BeaconRegionManager {
    NSMutableDictionary *_beacons;
    NSMutableArray *tmpRangedBeacons;
    int monitoredRegionCount;
    CBPeripheralManager *peripheralManager;
    
}

+ (BeaconRegionManager *)shared
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

-(BeaconRegionManager *)init{
    self = [super init];
    monitoredRegionCount = 0;
    _beacons = [[NSMutableDictionary alloc] init];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    
    [self updateAvailableRegions];
    [self updateMonitoredRegions];
    return self;
}


-(void)updateMonitoredRegions{
    //set monitored region read-only property with monitored regions
    _monitoredBeaconRegions = [self.locationManager monitoredRegions];
}

-(void)updateAvailableRegions{
  _availableManagedBeaconRegions = [[PlistManager shared] getAvailableManagedBeaconRegions];
  [self startMonitoringAllAvailableBeaconRegions];
}


//returns a beacon from the ranged list given a identifier, else emits log and returns nil
-(CLBeacon *)beaconWithId:(NSString *)identifier{
    ManagedBeaconRegion *beaconRegion = [self beaconRegionWithId:identifier];
    for (CLBeacon *beacon in self.rangedBeacons){
        if ([[beacon.proximityUUID UUIDString] isEqualToString:[beaconRegion.proximityUUID UUIDString]]) {
            return beacon;
        }
    }
    
    NSLog(@"No beacon with the specified ID is within range");
    return nil;
}
//returns a managed beacon region from the available regions (all in plist) given an identifier
-(ManagedBeaconRegion *)beaconRegionWithId:(NSString *)identifier{
    for (ManagedBeaconRegion *managedBeaconRegion in self.availableManagedBeaconRegions)
    {
        if ([managedBeaconRegion.identifier isEqualToString:identifier]) {
            return managedBeaconRegion;
        }
    }
    
    //No available beacon region with the specified ID was included in the available regions list
    return nil;
}

//returns a managed beacon region from the available regions (all in plist) given the UUID
//WARNING - beacons may have the same UUID
-(ManagedBeaconRegion *)beaconRegionWithUUID:(NSUUID *)UUID{
    for (ManagedBeaconRegion *beaconRegion in self.availableManagedBeaconRegions)
    {
        if ([[beaconRegion.proximityUUID UUIDString] isEqualToString:[UUID UUIDString]]) {
            return beaconRegion;
        }
    }
    
    //No available beacon region with the specified ID was included in the available regions list
    return nil;
}

-(void)startMonitoringBeaconInRegion:(ManagedBeaconRegion *)beaconRegion{

        if (beaconRegion != nil) {
            beaconRegion.notifyOnEntry = YES;
            beaconRegion.notifyOnExit = YES;
            beaconRegion.notifyEntryStateOnDisplay = NO;
            [self.locationManager startMonitoringForRegion:beaconRegion];
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            [self updateMonitoredRegions];
            monitoredRegionCount++;
        }
}

-(void)stopMonitoringBeaconInRegion:(ManagedBeaconRegion *)beaconRegion{
    
    if (beaconRegion != nil) {
        beaconRegion.notifyOnEntry = NO;
        beaconRegion.notifyOnExit = NO;
        beaconRegion.notifyEntryStateOnDisplay = NO;
        [self.locationManager stopMonitoringForRegion:beaconRegion];
        [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        [self updateMonitoredRegions];
        monitoredRegionCount--;
    }
}

//helper method to start monitoring all available beacon regions with no notifications
-(void)startMonitoringAllAvailableBeaconRegions{
    
    for (ManagedBeaconRegion *beaconRegion in self.availableManagedBeaconRegions)
    {
        if (beaconRegion != nil) {
            beaconRegion.notifyOnEntry = YES;
            beaconRegion.notifyOnExit = YES;
            beaconRegion.notifyEntryStateOnDisplay = NO;
            [self.locationManager startMonitoringForRegion:beaconRegion];
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            [self updateMonitoredRegions];
            monitoredRegionCount++;
        }
    }

}

//helper method to stop monitoring all available beacon regions
-(void)stopMonitoringAllAvailableBeaconRegions{
    
    for (ManagedBeaconRegion *beaconRegion in [[PlistManager shared] getAvailableManagedBeaconRegions])
    {
        if (beaconRegion != nil) {
            beaconRegion.notifyOnEntry = NO;
            beaconRegion.notifyOnExit = NO;
            beaconRegion.notifyEntryStateOnDisplay = NO;
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
            [self.locationManager stopMonitoringForRegion:beaconRegion];
            [self updateMonitoredRegions];
            //reset monitored region count
            monitoredRegionCount = 0;
        }
    }
    
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    
}


-(ManagedBeaconRegion *)convertToManagedBeaconRegion:(CLBeaconRegion *)region{

    ManagedBeaconRegion *managedRegion = [[ManagedBeaconRegion alloc] initWithProximityUUID:region.proximityUUID major:[region.major shortValue] minor:[region.minor shortValue] identifier:region.identifier];
    
    return managedRegion;
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    // CoreLocation will call this delegate method at 1 Hz with updated range information.
    // Beacons will be categorized and displayed by proximity.
    
    _rangedBeacons = beacons;
  
    
    //get closest beacon here TODO
    [self loadMatchingBeaconForRegion:[self convertToManagedBeaconRegion:region] FromBeacons:beacons];
    
    //set ivar to init read-only property
    //_monitoredBeaconRegions = [manager rangedRegions];
    
    
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"managerDidRangeBeacons"
     object:self];
    

    [self updateVistedStatsForRangedBeacons:beacons];

}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog( @"didEnterRegion" );
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"didExitRegion");
}


-(CLBeacon *)loadMatchingBeaconForRegion:(ManagedBeaconRegion *) beaconRegion FromBeacons:(NSArray *)beacons{
    for (CLBeacon *beacon in beacons) {
        
        if (beacon.major == beaconRegion.major && beacon.minor == beaconRegion.minor && [[beacon.proximityUUID UUIDString]isEqualToString:[beaconRegion.proximityUUID UUIDString]])
        {
            beaconRegion.beacon = beacon;
            return beacon;
        }
    }
    //no beacons match this region
    return nil;
}

-(void)updateVistedStatsForRangedBeacons:(NSArray *)rangedBeacons
{

    
    NSArray *unknownBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityUnknown]];
    if([unknownBeacons count])
        [_beacons setObject:unknownBeacons forKey:[NSNumber numberWithInt:CLProximityUnknown]];
    
    NSArray *immediateBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityImmediate]];
    if([immediateBeacons count])
        [_beacons setObject:immediateBeacons forKey:[NSNumber numberWithInt:CLProximityImmediate]];
    
    NSArray *nearBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityNear]];
    if([nearBeacons count])
        [_beacons setObject:nearBeacons forKey:[NSNumber numberWithInt:CLProximityNear]];
    
    NSArray *farBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityFar]];
    if([farBeacons count])
        [_beacons setObject:farBeacons forKey:[NSNumber numberWithInt:CLProximityFar]];
    
    //set read only parameter for detailed ranged beacons
    _rangedBeaconsDetailed = _beacons;
}

-(BOOL)isMonitored:(ManagedBeaconRegion *) beaconRegion{
    for (ManagedBeaconRegion *bRegion in self.monitoredBeaconRegions) {
        if ([bRegion.identifier isEqualToString:beaconRegion.identifier]){
            return true;
        }
    }
    return false;
}


- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    // A user can transition in or out of a region while the application is not running.
    // When this happens CoreLocation will launch the application momentarily, call this delegate method
    // and we will let the user know via a local notification.
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    ManagedBeaconRegion *managedBeaconRegion = [self beaconRegionWithId:region.identifier];

    
    if(state == CLRegionStateInside)
    {
        notification.alertBody = [NSString stringWithFormat:@"You're inside the region %@", region.identifier];
        [managedBeaconRegion timestampEntry];
    }
    else if(state == CLRegionStateOutside)
    {
        notification.alertBody = [NSString stringWithFormat:@"You're outside the region %@", region.identifier];
        [managedBeaconRegion timestampExit];
    }
    else
    {
        return;
    }
    
    
    // If the application is in the foreground, it will get a callback to application:didReceiveLocalNotification:.
    // If its not, iOS will display the notification to the user.
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

@end
