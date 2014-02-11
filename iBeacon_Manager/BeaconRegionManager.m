//
//  UABeaconManager.m
//  UABeacons
//
//  Created by David Crow on 10/3/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "BeaconRegionManager.h"
#import "BeaconManagerValues.h"
#import "UAPush.h"

@interface BeaconRegionManager ()

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation BeaconRegionManager
{
    @private
        int _monitoredRegionCount;
        //temporary store for detailed ranging
        NSMutableDictionary *_currentRangedBeacons;
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
    
    _plistManager = [[BeaconPlistManager alloc] init];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    _currentRangedBeacons = [[NSMutableDictionary alloc] init];
    _monitoredRegionCount = 0;

    return self;
}

-(void)startManager
{
    //clear monitoring on store location manager regions
    [[BeaconRegionManager shared] stopMonitoringAllBeaconRegions];
    //initialize ibeacon manager, load iBeacon plist, load available regions, start monitoring available regions
    [[BeaconRegionManager shared] loadAvailableRegions];
    [[BeaconRegionManager shared] startMonitoringAllAvailableBeaconRegions];
    [self loadBeaconStats];
}

-(void)stopManager
{
    //clear monitoring on store location manager regions
    [[BeaconRegionManager shared] stopMonitoringAllBeaconRegions];
}

-(void)checkiBeaconsEnabledState
{
    if([[NSUserDefaults standardUserDefaults] objectForKey:kBeaconsEnabled])
    {
        //if no saved switch state set to YES by default
        self.ibeaconsEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kBeaconsEnabled];
    }
    else
    {
        self.ibeaconsEnabled =  YES;
    }
}

-(void)setIbeaconsEnabled:(BOOL)ibeaconsEnabled
{
    if (ibeaconsEnabled != _ibeaconsEnabled)
    {
        _ibeaconsEnabled = ibeaconsEnabled;
    }
    
    //enable montoring based on switch state
    if (ibeaconsEnabled)
    {
        [self startManager];
    }
    else
    {
        [self stopManager];
        //[self removeAllBeaconTags];
    }
}

-(void)removeAllBeaconTags
{
    for (CLBeaconRegion *beaconRegion in self.availableBeaconRegionsList)
    {
        [[UAPush shared] removeTagFromCurrentDevice:[NSString stringWithFormat:@"%@%@", kExitTagPreamble, beaconRegion.identifier]];
        [[UAPush shared] removeTagFromCurrentDevice:[NSString stringWithFormat:@"%@%@", kEntryTagPreamble, beaconRegion.identifier]];
    }
    [[UAPush shared] updateRegistration];
}

-(void)syncMonitoredRegions
{
    //set monitored region read-only property with monitored regions
    _monitoredBeaconRegions = [self.locationManager monitoredRegions];
}

-(void)loadAvailableRegions
{
    _availableBeaconRegionsList = [_plistManager getAvailableBeaconRegionsList];
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
        [self syncMonitoredRegions];
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
        [self syncMonitoredRegions];
        _monitoredRegionCount--;
    }
}

//helper method to start monitoring all available beacon regions with no notifications
-(void)startMonitoringAllAvailableBeaconRegions
{
    for (CLBeaconRegion *beaconRegion in self.availableBeaconRegionsList)
    {
        if (beaconRegion != nil)
        {
            [self startMonitoringBeaconInRegion:beaconRegion];
        }
    }
       [self syncMonitoredRegions];
}

//helper method to stop monitoring all available beacon regions
-(void)stopMonitoringAllAvailableBeaconRegions
{
    for (CLBeaconRegion *beaconRegion in self.availableBeaconRegionsList)
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
            [self syncMonitoredRegions];
            //reset monitored region count
            _monitoredRegionCount = 0;
        }
    }
}

#pragma location manager callbacks

//this gets called once for each beacon regions at 1 hz
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    // CoreLocation will call this delegate method at 1 Hz once for each region
    
    //if a mutable array exists under key region.identifier, replace it's contents with the ranged beacons
    if ([_currentRangedBeacons objectForKey:region.identifier] && [[_currentRangedBeacons objectForKey:region.identifier] isKindOfClass:[NSMutableArray class]])
    {
        
        NSMutableArray *currentBeaconsInRegion = [_currentRangedBeacons objectForKey:region.identifier];
        currentBeaconsInRegion = [NSMutableArray arrayWithArray:beacons];
        [_currentRangedBeacons setObject:currentBeaconsInRegion forKey:region.identifier];
    }
    //if no mutable array exists under key, allocate mutable array and replace with ranged beacons
    else
    {
        NSMutableArray *currentBeaconsInRegion = [[NSMutableArray alloc] initWithArray:beacons];
        //place current ranged beacons for this region under this region's key
        [_currentRangedBeacons setObject:currentBeaconsInRegion forKey:region.identifier];
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"managerDidRangeBeacons"
     object:self];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSTimeInterval lastEntry = [[BeaconRegionManager shared] lastEntryForIdentifier:region.identifier];
    NSTimeInterval lastExit = [[BeaconRegionManager shared] lastExitForIdentifier:region.identifier];
    NSTimeInterval cumulativeTime = [[BeaconRegionManager shared] cumulativeTimeForIdentifier:region.identifier];
    
    [[UAPush shared] removeTagFromCurrentDevice:[NSString stringWithFormat:@"%@-%@", region.identifier, kExitTagPreamble]];
    [[UAPush shared] addTagToCurrentDevice:[NSString stringWithFormat:@"%@-%@", region.identifier, kEntryTagPreamble]];
    
    //[[UAPush shared] addTagToCurrentDevice:[NSString stringWithFormat:@"Entered-%@_At:%@", region.identifier, [NSDate dateWithTimeIntervalSince1970:lastEntry]]];

    UALOG(@"Updating tag");
    [[UAPush shared] updateRegistration];
    
    NSLog( @"didEnterRegion %@", region.identifier );
    [self timestampEntryForBeaconRegion:[self beaconRegionWithId:region.identifier]];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSTimeInterval lastEntry = [[BeaconRegionManager shared] lastEntryForIdentifier:region.identifier];
    NSTimeInterval lastExit = [[BeaconRegionManager shared] lastExitForIdentifier:region.identifier];
    NSTimeInterval cumulativeTime = [[BeaconRegionManager shared] cumulativeTimeForIdentifier:region.identifier];
    
    [[UAPush shared] removeTagFromCurrentDevice:[NSString stringWithFormat:@"%@-%@", region.identifier, kEntryTagPreamble]];
    [[UAPush shared] addTagToCurrentDevice:[NSString stringWithFormat:@"%@-%@", region.identifier, kExitTagPreamble]];
    
    UALOG(@"Updating tag");
    [[UAPush shared] updateRegistration];
    
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

    if(state == CLRegionStateInside)
    {
        [[UAPush shared] removeTagFromCurrentDevice:[NSString stringWithFormat:@"%@-%@", region.identifier, kExitTagPreamble]];
        [[UAPush shared] addTagToCurrentDevice:[NSString stringWithFormat:@"%@-%@", region.identifier, kEntryTagPreamble]];
        UALOG(@"Updating tag");
        NSLog( @"didEnterRegion %@", region.identifier );
                
        //if lastEntry is null then entry is when the app started in the region
        if (![[BeaconRegionManager shared] lastEntryForIdentifier:region.identifier])
        {
            [self timestampEntryForBeaconRegion:[self beaconRegionWithId:region.identifier]];
        }
    }
    else if(state == CLRegionStateOutside)
    {
        [[UAPush shared] removeTagFromCurrentDevice:[NSString stringWithFormat:@"%@-%@", region.identifier, kEntryTagPreamble]];
        [[UAPush shared] addTagToCurrentDevice:[NSString stringWithFormat:@"%@-%@", region.identifier, kExitTagPreamble]];
        NSLog(@"didExitRegion %@", region.identifier);
    }
    UALOG(@"Updating tag");
    [[UAPush shared] updateRegistration];
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
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kiBeaconStats])
    {
        self.beaconStats = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kiBeaconStats]];
    }
    else
    {
        self.beaconStats = [[NSMutableDictionary alloc] init];
        [self saveBeaconStats];
    }
}

-(void)saveBeaconStats
{
    [[NSUserDefaults standardUserDefaults] setObject:self.beaconStats forKey:kiBeaconStats];
}

-(void)clearAllBeaconStats
{
    self.beaconStats = nil;
    [[NSUserDefaults standardUserDefaults] setObject:self.beaconStats forKey:kiBeaconStats];
}

-(void)clearBeaconStatsForBeaconRegion:(CLBeaconRegion *)beaconRegion
{
    if ([self.beaconStats objectForKey:beaconRegion.identifier])
    {
    [self.beaconStats setObject:nil forKey:beaconRegion.identifier];
    }
    [self saveBeaconStats];
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
        if ([stats objectForKey:kLastEntry])
        {
            return [[stats objectForKey:kLastEntry] doubleValue];
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
        if ([stats objectForKey:kLastExit])
        {
            return [[stats objectForKey:kLastExit] doubleValue];
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
        if ([stats objectForKey:kCumulativeTime])
        {
            return [[stats objectForKey:kCumulativeTime] doubleValue];
        }
    }
    NSLog(@"No cumulativeTime for that identifier is available");
    return 0;
}

-(double)averageVisitTimeForIdentifier:(NSString *)identifier
{
    return [self cumulativeTimeForIdentifier:identifier]/[self visitsForIdentifier:identifier];
}

-(int)visitsForIdentifier:(NSString *)identifier
{
    if (self.beaconStats && [self.beaconStats objectForKey:identifier])
    {
        NSDictionary *stats = [self.beaconStats objectForKey:identifier];
        if ([stats objectForKey:kVisits])
        {
            return [[stats objectForKey:kVisits] intValue];
        }
    }
    NSLog(@"No visits for that identifier are available");
    return 0;
}

-(void)recordVisitForBeaconRegion:(CLBeaconRegion *)beaconRegion
{
    int visits;
    if (beaconRegion.identifier)
    {
        NSLog(@"visit recorded");
        //if beaconstats dict is present
        if ([self.beaconStats objectForKey:beaconRegion.identifier])
        {
            NSMutableDictionary *beaconRegionStats = [[NSMutableDictionary alloc] initWithDictionary:[self.beaconStats objectForKey:beaconRegion.identifier]];
            
            if ([self visitsForIdentifier:beaconRegion.identifier])
            {
                visits = [self visitsForIdentifier:beaconRegion.identifier] + 1;
            }
            else
            {
                visits = 1;
            }
            
            [beaconRegionStats setObject:[NSNumber numberWithInteger:visits] forKey:kVisits];
        }
        [self saveBeaconStats];
    }
}

-(void)timestampEntryForBeaconRegion:(CLBeaconRegion *)beaconRegion
{
    if (beaconRegion.identifier)
    {
        NSLog(@"timestamped entry");
        if ([self.beaconStats objectForKey:beaconRegion.identifier])
        {
            NSMutableDictionary *beaconRegionStats = [[NSMutableDictionary alloc] initWithDictionary:[self.beaconStats objectForKey:beaconRegion.identifier]];
            [beaconRegionStats setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:kLastEntry];
        }
        else
        {
            //create new dictionary for this region and add it to stats
            NSMutableDictionary *beaconRegionStats = [NSMutableDictionary new];
            [beaconRegionStats setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:kLastEntry];
            [self.beaconStats setObject:beaconRegionStats forKey:beaconRegion.identifier];
        }
        [self saveBeaconStats];
    }
    
    //record a visit on entry after necessary dictionary check is made
    [self recordVisitForBeaconRegion:beaconRegion];
}

-(void)timestampExitForBeaconRegion:(CLBeaconRegion *)beaconRegion
{
    if (beaconRegion.identifier)
    {
        NSLog(@"timestamped exit");
        if ([self.beaconStats objectForKey:beaconRegion.identifier])
        {
            NSMutableDictionary *beaconRegionStats = [[NSMutableDictionary alloc] initWithDictionary:[self.beaconStats objectForKey:beaconRegion.identifier]];
            [beaconRegionStats setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:kLastExit];
        }
        else
        {
            //create new dictionary for this region and add it to stats
            NSMutableDictionary *beaconRegionStats = [NSMutableDictionary new];
            [beaconRegionStats setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:kLastExit];
            [self.beaconStats setObject:beaconRegionStats forKey:beaconRegion.identifier];
        }
        [self saveBeaconStats];
    }
    
    [self calculateCumulativeTimeForBeaconRegion:beaconRegion];
}

-(void)calculateCumulativeTimeForBeaconRegion:(CLBeaconRegion *)beaconRegion
{
    NSTimeInterval cumulativeTime = [self cumulativeTimeForIdentifier:beaconRegion.identifier];
    NSTimeInterval entryTime = [self lastEntryForIdentifier:beaconRegion.identifier];
    NSTimeInterval exitTime = [self lastExitForIdentifier:beaconRegion.identifier];
    
    NSMutableDictionary *beaconRegionStats = [[NSMutableDictionary alloc] initWithDictionary:[self.beaconStats objectForKey:beaconRegion.identifier]];
    
    if (entryTime > 0)
    {
        cumulativeTime = cumulativeTime + (exitTime - entryTime);
        [beaconRegionStats setObject:[NSNumber numberWithDouble:cumulativeTime] forKey:kCumulativeTime];
    }
    else
    {
        [beaconRegionStats setObject:@0 forKey:kCumulativeTime];
    }
    [self saveBeaconStats];
}

#pragma non-essential helpers

//helper method for checking if a specific beacon region is monitored
-(BOOL)isMonitored:(CLBeaconRegion *)beaconRegion
{
    [self syncMonitoredRegions];
    for (CLBeaconRegion *bRegion in self.monitoredBeaconRegions) {
        if ([bRegion.identifier isEqualToString:beaconRegion.identifier]){
            return true;
        }
    }
    return false;
}

//returns a beacon from the ranged list given a identifier, else emits log and returns nil
-(CLBeacon *)beaconWithId:(NSString *)identifier
{
    CLBeaconRegion *beaconRegion = [self beaconRegionWithId:identifier];
    NSMutableArray *beacons;
    //this lever of checking probably isn't completely necessary
    if ([_currentRangedBeacons objectForKey:identifier] && [[_currentRangedBeacons objectForKey:identifier] isKindOfClass:[NSMutableArray class]]) {
        beacons = [_currentRangedBeacons objectForKey:identifier];
    }

    if (beacons)
    {
        for (CLBeacon *beacon in beacons){
            if ([[beacon.proximityUUID UUIDString] isEqualToString:[beaconRegion.proximityUUID UUIDString]]) {
                return beacon;
            }
        }
    }
    //No beacon with the specified ID is within range
    return nil;
}

//returns a beacon regions from the available regions (all in plist) given an identifier
-(CLBeaconRegion *)beaconRegionWithId:(NSString *)identifier
{
    for (CLBeaconRegion *beaconRegion in self.availableBeaconRegionsList)
    {
        if ([beaconRegion.identifier isEqualToString:identifier]) {
            return beaconRegion;
        }
    }
    //No available beacon region with the specified ID was included in the available regions list
    return nil;
}

@end
