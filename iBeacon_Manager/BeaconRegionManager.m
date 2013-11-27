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

@implementation BeaconRegionManager
{
    ManagedBeaconRegion *currentManagedRegion;
    int monitoredRegionCount;
    //temporary store for detailed ranging
    NSMutableDictionary *tmpRangedBeacons;
}

+ (BeaconRegionManager *)shared
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

-(BeaconRegionManager *)init
{
    self = [super init];
    monitoredRegionCount = 0;
    tmpRangedBeacons = [[NSMutableDictionary alloc] init];
    currentManagedRegion = [[ManagedBeaconRegion alloc] init];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    _plistManager = [[PlistManager alloc] init];
    return self;
}

-(void)loadMonitoredRegions
{
    //set monitored region read-only property with monitored regions
    _monitoredBeaconRegions = [self.locationManager monitoredRegions];
}

-(void)loadAvailableRegions
{
  _availableManagedBeaconRegions = [_plistManager getAvailableManagedBeaconRegions];
  [self startMonitoringAllAvailableBeaconRegions];
}


//returns a beacon from the ranged list given a identifier, else emits log and returns nil
-(CLBeacon *)beaconWithId:(NSString *)identifier
{
    ManagedBeaconRegion *beaconRegion = [self beaconRegionWithId:identifier];
    for (CLBeacon *beacon in self.rangedBeacons){
        if ([[beacon.proximityUUID UUIDString] isEqualToString:[beaconRegion.proximityUUID UUIDString]]) {
            return beacon;
        }
    }
    
    //No beacon with the specified ID is within range
    return nil;
}

//returns a beacon regions from the available regions (all in plist) given and identifier
-(ManagedBeaconRegion *)beaconRegionWithId:(NSString *)identifier
{
    for (ManagedBeaconRegion *managedBeaconRegion in self.availableManagedBeaconRegions)
    {
        if ([managedBeaconRegion.identifier isEqualToString:identifier]) {
            return managedBeaconRegion;
        }
    }
    
    //No available beacon region with the specified ID was included in the available regions list
    return nil;
}

-(void)loadHostedPlistFromUrl:(NSURL*)url{

}


//returns a managed beacon region from the available regions (all in plist) given the UUID
//WARNING - beacons may have the same UUID
-(ManagedBeaconRegion *)beaconRegionWithUUID:(NSUUID *)UUID
{
    for (ManagedBeaconRegion *beaconRegion in self.availableManagedBeaconRegions)
    {
        if ([[beaconRegion.proximityUUID UUIDString] isEqualToString:[UUID UUIDString]]) {
            return beaconRegion;
        }
    }
    
    //No available beacon region with the specified ID was included in the available regions list
    return nil;
}

-(void)startMonitoringBeaconInRegion:(CLBeaconRegion *)beaconRegion
{

        if (beaconRegion != nil) {
            beaconRegion.notifyOnEntry = YES;
            beaconRegion.notifyOnExit = YES;
            beaconRegion.notifyEntryStateOnDisplay = NO;
            [self.locationManager startMonitoringForRegion:beaconRegion];
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            [self loadMonitoredRegions];
            monitoredRegionCount++;
        }
}

-(void)stopMonitoringBeaconInRegion:(CLBeaconRegion *)beaconRegion
{
    
    if (beaconRegion != nil) {
        beaconRegion.notifyOnEntry = NO;
        beaconRegion.notifyOnExit = NO;
        beaconRegion.notifyEntryStateOnDisplay = NO;
        [self.locationManager stopMonitoringForRegion:beaconRegion];
        [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        [self loadMonitoredRegions];
        monitoredRegionCount--;
    }
}

//helper method to start monitoring all available beacon regions with no notifications
-(void)startMonitoringAllAvailableBeaconRegions
{
    
    for (ManagedBeaconRegion *beaconRegion in self.availableManagedBeaconRegions)
    {
        if (beaconRegion != nil) {
            beaconRegion.notifyOnEntry = YES;
            beaconRegion.notifyOnExit = YES;
            beaconRegion.notifyEntryStateOnDisplay = NO;
            [self.locationManager startMonitoringForRegion:beaconRegion];
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            [self loadMonitoredRegions];
            monitoredRegionCount++;
        }
    }

}

//helper method to stop monitoring all available beacon regions
-(void)stopMonitoringAllAvailableBeaconRegions
{
    
    for (ManagedBeaconRegion *beaconRegion in [_plistManager getAvailableManagedBeaconRegions])
    {
        if (beaconRegion != nil) {
            beaconRegion.notifyOnEntry = NO;
            beaconRegion.notifyOnExit = NO;
            beaconRegion.notifyEntryStateOnDisplay = NO;
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
            [self.locationManager stopMonitoringForRegion:beaconRegion];
            [self loadMonitoredRegions];
            //reset monitored region count
            monitoredRegionCount = 0;
        }
    }
    
}

-(ManagedBeaconRegion *)convertToManagedBeaconRegion:(CLBeaconRegion *)region
{

    ManagedBeaconRegion *managedRegion = [[ManagedBeaconRegion alloc] initWithProximityUUID:region.proximityUUID major:[region.major shortValue] minor:[region.minor shortValue] identifier:region.identifier];
    
    return managedRegion;
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    // CoreLocation will call this delegate method at 1 Hz with updated range
    currentManagedRegion = [self beaconRegionWithId:region.identifier];
    _rangedBeacons = beacons;
  
    if (beacons.count > 0){
        currentManagedRegion.beacon = beacons[0];
    }
        
    
    //get closest beacon here TODO
    [self loadMatchingBeaconForRegion:[self convertToManagedBeaconRegion:region] FromBeacons:beacons];
    
    //set ivar to init read-only property
    //_monitoredBeaconRegions = [manager rangedRegions];
    
    
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"managerDidRangeBeacons"
     object:self];
    

    [self updateVistedStatsForRangedBeacons:beacons];

}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog( @"didEnterRegion %@", region.identifier );
    ManagedBeaconRegion *managedBeaconRegion = [self beaconRegionWithId:region.identifier];
    [managedBeaconRegion timestampEntry];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"didExitRegion %@", region.identifier);
    ManagedBeaconRegion *managedBeaconRegion = [self beaconRegionWithId:region.identifier];
    [managedBeaconRegion timestampExit];
}


-(CLBeacon *)loadMatchingBeaconForRegion:(ManagedBeaconRegion *) beaconRegion FromBeacons:(NSArray *)beacons
{
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
        [tmpRangedBeacons setObject:unknownBeacons forKey:[NSNumber numberWithInt:CLProximityUnknown]];
    
    NSArray *immediateBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityImmediate]];
    if([immediateBeacons count])
        [tmpRangedBeacons setObject:immediateBeacons forKey:[NSNumber numberWithInt:CLProximityImmediate]];
    
    NSArray *nearBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityNear]];
    if([nearBeacons count])
        [tmpRangedBeacons setObject:nearBeacons forKey:[NSNumber numberWithInt:CLProximityNear]];
    
    NSArray *farBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityFar]];
    if([farBeacons count])
        [tmpRangedBeacons setObject:farBeacons forKey:[NSNumber numberWithInt:CLProximityFar]];
    
    //set read only parameter for detailed ranged beacons
    _rangedBeaconsDetailed = tmpRangedBeacons;
}

//helper method for checking if a specific beacon region is monitored
-(BOOL)isMonitored:(ManagedBeaconRegion *)beaconRegion
{
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


    
    if(state == CLRegionStateInside)
    {
        notification.alertBody = [NSString stringWithFormat:@"You're inside the region %@", region.identifier];
//        ManagedBeaconRegion *managedBeaconRegion = [self beaconRegionWithId:region.identifier];
//        if (managedBeaconRegion.beacon.accuracy)
//            [managedBeaconRegion timestampEntry];
        
    }
    else if(state == CLRegionStateOutside)
    {
        notification.alertBody = [NSString stringWithFormat:@"You're outside the region %@", region.identifier];
//        ManagedBeaconRegion *managedBeaconRegion = [self beaconRegionWithId:region.identifier];
//        if (managedBeaconRegion.beacon.accuracy<0)
//            [managedBeaconRegion timestampExit];
    }
    else
    {
        return;
    }
    
    
    // If the application is in the foreground, it will get a callback to application:didReceiveLocalNotification:.
    // If its not, iOS will display the notification to the user.
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"%@", error);

}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
NSLog(@"%@", error);

}

@end
