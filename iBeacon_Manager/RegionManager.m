//
//  UABeaconManager.m
//  UABeacons
//
//  Created by David Crow on 10/3/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "RegionManager.h"


@interface RegionManager ()

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation RegionManager {
    NSMutableDictionary *_beacons;
    NSMutableArray *tagArray;
    CGFloat bleatTime;
    NSMutableDictionary *visited;
    int monitoredRegionCount;
    CBPeripheralManager *peripheralManager;
    int goatX;
    int goatY;
}

+ (RegionManager *)shared
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

-(RegionManager *)init{
    self = [super init];
    monitoredRegionCount = 0;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    _availableBeaconRegions = [[PlistManager shared] getAvailableBeaconRegions];
    //this should be initialized from persistent storage at some point
    visited = [[NSMutableDictionary alloc] init];
    
    for (CLBeaconRegion *beaconRegion in self.availableBeaconRegions)
    {
        if (beaconRegion != nil) {
            beaconRegion.notifyOnEntry = YES;
            beaconRegion.notifyOnExit = NO;
            //beaconRegion.notifyEntryStateOnDisplay = YES;
            [self.locationManager startMonitoringForRegion:beaconRegion];
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            monitoredRegionCount++;
        }
    }
    
    //set monitored region read-only property with monitored regions
    _monitoredBeaconRegions = [self.locationManager monitoredRegions];
    return self;
}


//returns a beacon from the ranged list given a identifier, else emits log and returns nil
-(CLBeacon *)beaconWithId:(NSString *)identifier{
    CLBeaconRegion *beaconRegion = [self beaconRegionWithId:identifier];
    for (CLBeacon *beacon in self.rangedBeacons){
        if ([[beacon.proximityUUID UUIDString] isEqualToString:[beaconRegion.proximityUUID UUIDString]]) {
            return beacon;
        }
    }
    NSLog(@"No beacon with the specified ID is within range");
    return nil;
}
//returns a beacon regions from the available regions (all in plist) given and identifier
-(CLBeaconRegion *)beaconRegionWithId:(NSString *)identifier{
    for (CLBeaconRegion *beaconRegion in self.availableBeaconRegions)
    {
        if ([beaconRegion.identifier isEqualToString:identifier]) {
            return beaconRegion;
        }
    }
    
    NSLog(@"No available beacon region with the specified ID was included in the available regions list");
    return nil;
}

-(void)startMonitoringBeaconInRegion:(CLBeaconRegion *)beaconRegion{

        if (beaconRegion != nil) {
            beaconRegion.notifyOnEntry = NO;
            beaconRegion.notifyOnExit = NO;
            beaconRegion.notifyEntryStateOnDisplay = NO;
            [self.locationManager startMonitoringForRegion:beaconRegion];
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            monitoredRegionCount++;
        }
}

-(void)stopMonitoringBeaconInRegion:(CLBeaconRegion *)beaconRegion{
    
    if (beaconRegion != nil) {
        beaconRegion.notifyOnEntry = NO;
        beaconRegion.notifyOnExit = NO;
        beaconRegion.notifyEntryStateOnDisplay = NO;
        [self.locationManager stopMonitoringForRegion:beaconRegion];
        [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        monitoredRegionCount++;
    }
}

//helper method to start monitoring all available beacon regions with no notifications
-(void)startMonitoringAllAvailableBeaconRegions{
    
    for (CLBeaconRegion *beaconRegion in self.availableBeaconRegions)
    {
        if (beaconRegion != nil) {
            beaconRegion.notifyOnEntry = NO;
            beaconRegion.notifyOnExit = NO;
            beaconRegion.notifyEntryStateOnDisplay = NO;
            [self.locationManager startMonitoringForRegion:beaconRegion];
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            monitoredRegionCount++;
        }
    }

}

//helper method to stop monitoring all available beacon regions
-(void)stopMonitoringAllAvailableBeaconRegions{
    
    for (CLBeaconRegion *beaconRegion in [[PlistManager shared] getAvailableBeaconRegions])
    {
        if (beaconRegion != nil) {
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
            [self.locationManager stopMonitoringForRegion:beaconRegion];
            //reset monitored region count
            monitoredRegionCount = 0;
        }
    }
    
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    // CoreLocation will call this delegate method at 1 Hz with updated range information.
    // Beacons will be categorized and displayed by proximity.
    
    self.rangedBeacons = beacons;
    self.currentRegion = region;
    //set ivar to init read-only property
    //_monitoredBeaconRegions = [manager rangedRegions];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"managerDidRangeBeacons"
     object:self];

    [self updateVistedMetricsForRangedBeacons:beacons];

}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog( @"didEnterRegion" );
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"didExitRegion");
}



-(void)updateVistedMetricsForRegionIdentifier:(NSString *) identifier{

}

-(void)updateVistedMetricsForRangedBeacons:(NSArray *)rangedBeacons
{
    //this is required to have the most up to date list for getting identifiers for uuids
    [[PlistManager shared] loadReadableBeaconRegions];
    
    for (CLBeacon *beacon in rangedBeacons)
    {
        //If the current beacon UUID is missing form the visited regions, make it a dictionary add it to the visited regions
        
        int value;
        NSString *title = [[PlistManager shared] identifierForUUID:[beacon proximityUUID]];
        //initial values
        NSNumber *visits = [NSNumber numberWithInt:1];
        NSNumber *totalVisitTime = [NSNumber numberWithInt:1];
        //each key is appended with title ex. title_visits
        NSString *visitsKey = [NSString stringWithFormat:@"%@_visits",title];
        NSString *totalVisitTimeKey = [NSString stringWithFormat:@"%@_totalVisitTime",title];
        
        if ([self.visitedBeaconRegions valueForKey:visitsKey]) {
            value = [visits intValue];
            visits = [NSNumber numberWithInt:value + 1];
            [visited setValue:visits forKey:visitsKey];
        }
        else{
            //new beacon region (no such visit key exists)
            [visited setValue:visits forKey:visitsKey];
        }
        
        if ([self.visitedBeaconRegions valueForKey:totalVisitTimeKey]) {
            value = [totalVisitTimeKey intValue];
            totalVisitTime = [NSNumber numberWithInt:value + 1];
            [visited setValue:totalVisitTime forKey:totalVisitTimeKey];
        }
        else{
            //new beacon region (no such visit key exists)
            [visited setValue:totalVisitTime forKey:totalVisitTimeKey];
        }
        
        //set the read-only property
        _visitedBeaconRegions = visited;

    }
}


- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    // A user can transition in or out of a region while the application is not running.
    // When this happens CoreLocation will launch the application momentarily, call this delegate method
    // and we will let the user know via a local notification.
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    [[RegionManager shared] updateVistedMetricsForRegionIdentifier:region.identifier];
    
    if(state == CLRegionStateInside)
    {
        notification.alertBody = [NSString stringWithFormat:@"You're inside the region %@", region.identifier];
    }
    else if(state == CLRegionStateOutside)
    {
        notification.alertBody = [NSString stringWithFormat:@"You're outside the region %@", region.identifier];
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
