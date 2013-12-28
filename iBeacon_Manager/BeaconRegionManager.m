//
//  UABeaconManager.m
//  UABeacons
//
//  Created by David Crow on 10/3/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "BeaconRegionManager.h"
#import "BeaconManagerValues.h"


@interface BeaconRegionManager ()

@property (strong, nonatomic) CLLocationManager *locationManager;

@end


@implementation BeaconRegionManager
{
    int _monitoredRegionCount;
    //temporary store for detailed ranging
    NSMutableDictionary *_tmpRangedBeacons;
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
    

    _plistManager = [[PlistManager alloc] init];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    _tmpRangedBeacons = [[NSMutableDictionary alloc] init];
    _monitoredRegionCount = 0;
    
    //add observer to kMotherShipiBeaconsEnabled keypath, will call observeValueForKeyPath
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:kMotherShipiBeaconsEnabled
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    return self;
}

-(void)startManager
{
    //clear monitoring on store location manager regions
    //[[BeaconRegionManager shared] stopMonitoringAllBeaconRegions];
    //initialize ibeacon manager, load iBeacon plist, load available regions, start monitoring available regions
    //[[[BeaconRegionManager shared] plistManager] loadLocalPlist];
    //[[[BeaconRegionManager shared] plistManager] loadHostedPlistWithUrl:[NSURL URLWithString:@"http://bit.ly/1iIvvKQ"]];
    [[BeaconRegionManager shared] loadAvailableRegions];
    [[BeaconRegionManager shared] startMonitoringAllAvailableBeaconRegions];
    [self loadBeaconStats];
}

-(void)stopManager
{
    //clear monitoring on store location manager regions
    [[BeaconRegionManager shared] stopMonitoringAllBeaconRegions];
    //optionally clear beacons stats, this should probably be done after a prompt
    //[self clearBeaconStats];
}

-(void)checkiBeaconsEnabledState
{
    if([[NSUserDefaults standardUserDefaults] objectForKey:kMotherShipiBeaconsEnabled] == nil)
    {
        //if no saved switch state set to YES by default
        self.ibeaconsEnabled = YES;
    }
    else
    {
        //ui will store switch state under kMotherShipiBeaconsEnabled
        self.ibeaconsEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kMotherShipiBeaconsEnabled];
    }
    
    //enable montoring based on switch state
    if (self.ibeaconsEnabled == YES)
    {
        [self startManager];
    }
    else
    {
        [self stopManager];
    }
}

-(void)loadMonitoredRegions
{
    //set monitored region read-only property with monitored regions
    _monitoredBeaconRegions = [self.locationManager monitoredRegions];
}

-(void)loadAvailableRegions
{
    _availableManagedBeaconRegionsList = [_plistManager getAvailableBeaconRegionsList];
}

#pragma monitoring stop/start helpers

-(void)startMonitoringBeaconInRegion:(CLBeaconRegion *)beaconRegion
{
    if (beaconRegion != nil) {
        beaconRegion.notifyOnEntry = YES;
        beaconRegion.notifyOnExit = YES;
        beaconRegion.notifyEntryStateOnDisplay = NO;
        [self.locationManager startMonitoringForRegion:beaconRegion];
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        [self loadMonitoredRegions];
        _monitoredRegionCount++;
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
        _monitoredRegionCount--;
    }
}

//helper method to start monitoring all available beacon regions with no notifications
-(void)startMonitoringAllAvailableBeaconRegions
{
    for (CLBeaconRegion *beaconRegion in self.availableManagedBeaconRegionsList)
    {
        if (beaconRegion != nil)
        {
            [self startMonitoringBeaconInRegion:beaconRegion];
        }
    }
       [self loadMonitoredRegions];
}

//helper method to stop monitoring all available beacon regions
-(void)stopMonitoringAllAvailableBeaconRegions
{
    for (CLBeaconRegion *beaconRegion in self.availableManagedBeaconRegionsList)
    {
            [self stopMonitoringBeaconInRegion:beaconRegion];
            //reset monitored region count
            _monitoredRegionCount = 0;
        
    }
}

//stops monitoring all beacons in the current location monitor list
-(void)stopMonitoringAllBeaconRegions
{
    for (CLBeaconRegion *beaconRegion in [self.locationManager monitoredRegions])
    {
        if (beaconRegion != nil) {
            beaconRegion.notifyOnEntry = NO;
            beaconRegion.notifyOnExit = NO;
            beaconRegion.notifyEntryStateOnDisplay = NO;
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
            [self.locationManager stopMonitoringForRegion:beaconRegion];
            [self loadMonitoredRegions];
            //reset monitored region count
            _monitoredRegionCount = 0;
        }
    }
}

#pragma location manager callbacks

//this gets called once for each beacon regions at 1 hz
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    // CoreLocation will call this delegate method at 1 Hz
    _rangedBeacons = beacons;
    [self saveBeaconStats];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"managerDidRangeBeacons"
     object:self];
    
    [self updateVistedStatsForRangedBeacons:beacons];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSTimeInterval lastEntry = [[BeaconRegionManager shared] lastEntryForIdentifier:region.identifier];
    NSTimeInterval lastExit = [[BeaconRegionManager shared] lastExitForIdentifier:region.identifier];
    NSTimeInterval cumulativeTime = [[BeaconRegionManager shared] cumulativeTimeForIdentifier:region.identifier];
    
//    [[UAPush shared] removeTagFromCurrentDevice:[NSString stringWithFormat:@"Outside-%@", region.identifier]];
//    [[UAPush shared] addTagToCurrentDevice:[NSString stringWithFormat:@"Inside-%@", region.identifier]];
//    
//    //[[UAPush shared] addTagToCurrentDevice:[NSString stringWithFormat:@"Entered-%@_At:%@", region.identifier, [NSDate dateWithTimeIntervalSince1970:lastEntry]]];
//
//    UALOG(@"Updating tag");
//    [[UAPush shared] updateRegistration];
    
    NSLog( @"didEnterRegion %@", region.identifier );
    [self timestampEntryForBeaconRegion:[self beaconRegionWithId:region.identifier]];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSTimeInterval lastEntry = [[BeaconRegionManager shared] lastEntryForIdentifier:region.identifier];
    NSTimeInterval lastExit = [[BeaconRegionManager shared] lastExitForIdentifier:region.identifier];
    NSTimeInterval cumulativeTime = [[BeaconRegionManager shared] cumulativeTimeForIdentifier:region.identifier];
    
//    [[UAPush shared] removeTagFromCurrentDevice:[NSString stringWithFormat:@"Outside-%@", region.identifier]];
//    [[UAPush shared] addTagToCurrentDevice:[NSString stringWithFormat:@"Inside-%@", region.identifier]];
//    
//    //[[UAPush shared] addTagToCurrentDevice:[NSString stringWithFormat:@"Exited-%@_At:%@_tt:%fs", region.identifier,[NSDate dateWithTimeIntervalSince1970:lastExit],cumulativeTime]];
//    
//    UALOG(@"Updating tag");
//    [[UAPush shared] updateRegistration];
    
    NSLog(@"didExitRegion %@", region.identifier);
    //exit timestamp includes cumulative time measurement
    [self timestampExitForBeaconRegion:[self beaconRegionWithId:region.identifier]];
}

//this is redundant but ensures all regions are tagged as inside or outside
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    // A user can transition in or out of a region while the application is not running.
    // When this happens CoreLocation will launch the application momentarily, call this delegate method
    // and we will let the user know via a local notification.

//    if(state == CLRegionStateInside)
//    {
//        [[UAPush shared] removeTagFromCurrentDevice:[NSString stringWithFormat:@"Outside-%@", region.identifier]];
//        [[UAPush shared] addTagToCurrentDevice:[NSString stringWithFormat:@"Inside-%@", region.identifier]];
//        UALOG(@"Updating tag");
//        NSLog( @"didEnterRegion %@", region.identifier );
//    }
//    else if(state == CLRegionStateOutside)
//    {
//        [[UAPush shared] removeTagFromCurrentDevice:[NSString stringWithFormat:@"Inside-%@", region.identifier]];
//        [[UAPush shared] addTagToCurrentDevice:[NSString stringWithFormat:@"Outside-%@", region.identifier]];
//        NSLog(@"didExitRegion %@", region.identifier);
//    }
//    UALOG(@"Updating tag");
//    [[UAPush shared] updateRegistration];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"%@", error);
}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"%@", error);
}

#pragma beacon stats helpers

-(void)loadBeaconStats
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"beaconStats"])
    {
        self.beaconStats = [[NSUserDefaults standardUserDefaults] objectForKey:@"beaconStats"];
    }
    else
    {
        self.beaconStats = [[NSMutableDictionary alloc] init];
    }
}

-(void)saveBeaconStats
{
    [[NSUserDefaults standardUserDefaults] setObject:self.beaconStats forKey:@"beaconStats"];
}

-(void)clearBeaconStats
{
    for (id key in self.beaconStats) {
        [self.beaconStats removeObjectForKey:key];
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.beaconStats forKey:@"beaconStats"];
}


-(NSMutableDictionary *)beaconStatsForIdentifier:(NSString *)identifier
{
    if (self.beaconStats && [self.beaconStats objectForKey:identifier])
    {
        return [self.beaconStats objectForKey:identifier];
    }
    NSLog(@"No beacon stats for that identifier are available");
    return nil;
}

-(double)lastEntryForIdentifier:(NSString *)identifier
{
    if (self.beaconStats && [self.beaconStats objectForKey:identifier])
    {
        NSDictionary *stats = [self.beaconStats objectForKey:identifier];
        if ([stats objectForKey:@"lastEntry"])
        {
            return [[stats objectForKey:@"lastEntry"] doubleValue];
        }

    }
    NSLog(@"No lastEntry for that identifier is available");
    return 0;
}

-(double)lastExitForIdentifier:(NSString *)identifier
{
    if (self.beaconStats && [self.beaconStats objectForKey:identifier])
    {
        
        NSDictionary *stats = [self.beaconStats objectForKey:identifier];
        if ([stats objectForKey:@"lastExit"])
        {
            return [[stats objectForKey:@"lastExit"] doubleValue];
        }

    }
    NSLog(@"No lastExit for that identifier is available");
    return 0;
}

-(double)cumulativeTimeForIdentifier:(NSString *)identifier
{
    if (self.beaconStats && [self.beaconStats objectForKey:identifier])
    {
        NSDictionary *stats = [self.beaconStats objectForKey:identifier];
        if ([stats objectForKey:@"cumulativeTime"])
        {
            return [[stats objectForKey:@"cumulativeTime"] doubleValue];
        }
    }
    NSLog(@"No cumulativeTime for that identifier is available");
    return 0;
}

-(void)timestampEntryForBeaconRegion:(CLBeaconRegion *)beaconRegion
{
    
    if (beaconRegion.identifier)
    {
        NSLog(@"timestamped entry");
        if ([self.beaconStats objectForKey:beaconRegion.identifier])
        {
                NSMutableDictionary *beaconRegionStats = [self.beaconStats objectForKey:beaconRegion.identifier];
                [beaconRegionStats setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"lastEntry"];
        }
        else
        {
                //create new dictionary for this region and add it to stats
                NSMutableDictionary *beaconRegionStats = [NSMutableDictionary new];
                [beaconRegionStats setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"lastEntry"];
                [self.beaconStats setObject:beaconRegionStats forKey:beaconRegion.identifier];
        }
        [self saveBeaconStats];
    }
}

-(void)timestampExitForBeaconRegion:(CLBeaconRegion *)beaconRegion
{
    if (beaconRegion.identifier)
    {
        NSLog(@"timestamped exit");
        if ([self.beaconStats objectForKey:beaconRegion.identifier])
        {
            NSMutableDictionary *beaconRegionStats = [self.beaconStats objectForKey:beaconRegion.identifier];
            [beaconRegionStats setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"lastExit"];
        }
        else
        {
            //create new dictionary for this region and add it to stats
            NSMutableDictionary *beaconRegionStats = [NSMutableDictionary new];
            [beaconRegionStats setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"lastExit"];
            [self.beaconStats setObject:beaconRegionStats forKey:beaconRegion.identifier];
        }
        [self saveBeaconStats];
    }
    //make call to calculate new cumulative time for region
    [self calculateCumulativeTimeForBeaconRegion:beaconRegion];
}

-(void)calculateCumulativeTimeForBeaconRegion:(CLBeaconRegion *)beaconRegion
{
    NSTimeInterval cumulativeTime;
    NSTimeInterval entryTime = [self lastEntryForIdentifier:beaconRegion.identifier];
    NSTimeInterval exitTime = [self lastExitForIdentifier:beaconRegion.identifier];
    
    NSMutableDictionary *beaconRegionStats = [self.beaconStats objectForKey:beaconRegion.identifier];
    
    if (entryTime > 0)
    {
        cumulativeTime = [self cumulativeTimeForIdentifier:beaconRegion.identifier] + (exitTime - entryTime);
        [beaconRegionStats setObject:[NSNumber numberWithDouble:cumulativeTime] forKey:@"cumulativeTime"];
    }
    else
    {
        [beaconRegionStats setObject:@0 forKey:@"cumulativeTime"];
    }
}


//TODO finish filtering by proximity and tagging
-(void)updateVistedStatsForRangedBeacons:(NSArray *)rangedBeacons
{
    //[tmpRangedBeacons removeAllObjects];
    NSArray *unknownBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityUnknown]];
    if([unknownBeacons count])
        [_tmpRangedBeacons setObject:unknownBeacons forKey:[NSNumber numberWithInt:CLProximityUnknown]];
    
    NSArray *immediateBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityImmediate]];
    if([immediateBeacons count])
        [_tmpRangedBeacons setObject:immediateBeacons forKey:[NSNumber numberWithInt:CLProximityImmediate]];
    
    NSArray *nearBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityNear]];
    if([nearBeacons count])
        [_tmpRangedBeacons setObject:nearBeacons forKey:[NSNumber numberWithInt:CLProximityNear]];
    
    NSArray *farBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", CLProximityFar]];
    if([farBeacons count])
        [_tmpRangedBeacons setObject:farBeacons forKey:[NSNumber numberWithInt:CLProximityFar]];
    
    //set read only parameter for detailed ranged beacons
    _rangedBeaconsDetailed = _tmpRangedBeacons;
}

#pragma non-essential helpers

//helper method for checking if a specific beacon region is monitored
-(BOOL)isMonitored:(CLBeaconRegion *)beaconRegion
{
    for (CLBeaconRegion *beaconRegion in self.monitoredBeaconRegions) {
        if ([beaconRegion.identifier isEqualToString:beaconRegion.identifier]){
            return true;
        }
    }
    return false;
}

//returns a beacon from the ranged list given a identifier, else emits log and returns nil
-(CLBeacon *)beaconWithId:(NSString *)identifier
{
    CLBeaconRegion *beaconRegion = [self beaconRegionWithId:identifier];
    for (CLBeacon *beacon in self.rangedBeacons){
        if ([[beacon.proximityUUID UUIDString] isEqualToString:[beaconRegion.proximityUUID UUIDString]]) {
            return beacon;
        }
    }
    //No beacon with the specified ID is within range
    return nil;
}

//returns a beacon regions from the available regions (all in plist) given an identifier
-(CLBeaconRegion *)beaconRegionWithId:(NSString *)identifier
{
    for (CLBeaconRegion *managedBeaconRegion in self.availableManagedBeaconRegionsList)
    {
        if ([managedBeaconRegion.identifier isEqualToString:identifier]) {
            return managedBeaconRegion;
        }
    }
    //No available beacon region with the specified ID was included in the available regions list
    return nil;
}

//called whenever kMotherShipiBeaconsEnabled changes
- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context
{
    if([keyPath isEqual:kMotherShipiBeaconsEnabled])
    {
        [self checkiBeaconsEnabledState];
    }
}

@end
