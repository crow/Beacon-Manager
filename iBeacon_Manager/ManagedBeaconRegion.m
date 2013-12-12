//
//  ManagedBeaconRegion.m
//  iBeacon_Manager
//
//  Created by David Crow on 11/15/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "ManagedBeaconRegion.h"
#import "BeaconRegionManager.h"


@interface ManagedBeaconRegion ()

@end

@implementation ManagedBeaconRegion
{
    NSMutableDictionary *beaconStats;
}

//TODO add description method so the ManagedBeaconRegion shows up correctly in the debugger
//- (NSString *)description
//{
//    return [NSString stringWithFormat:@"\nproximityUUID: %@ \nBeer name: %@\nIBUs = %3.2f Categories: %@", proximityUUID, beerName, beerIBU, arrayHops];
//}

- (id)initWithProximityUUID:(NSUUID *)proximityUUID identifier:(NSString *)identifier
{
    self = [super initWithProximityUUID:proximityUUID identifier:identifier];
    if (self) {
        [self initManagedBeaconRegion];
    }
    return self;
}

- (id)initWithProximityUUID:(NSUUID *)proximityUUID major:(CLBeaconMajorValue)major identifier:(NSString *)identifier
{
    self = [super initWithProximityUUID:proximityUUID major:major identifier:identifier];
    if (self) {
        [self initManagedBeaconRegion];
    }
    return self;
}

- (id)initWithProximityUUID:(NSUUID *)proximityUUID major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier
{
    
    self = [super initWithProximityUUID:proximityUUID major:major minor:minor identifier:identifier];
    
    if (self) {
        [self initManagedBeaconRegion];
    }
    return self;
}

-(void)initManagedBeaconRegion
{
    beaconStats = [[NSMutableDictionary alloc] init];
    [self loadSavedBeaconStats];
}

-(void)loadSavedBeaconStats
{
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:self.identifier])
    {
        beaconStats = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:self.identifier]];
        
        if ([beaconStats objectForKey:@"lastEntry"])
            self.lastEntry = [[beaconStats objectForKey:@"lastEntry"] doubleValue];//double check that this is OK (store the interval as a NSNumber)
        else
        {
            self.lastEntry = 0;
        }
        if ([beaconStats objectForKey:@"lastExit"])
            self.lastExit = [[beaconStats objectForKey:@"lastExit"] doubleValue];//double check that this is OK (store the interval as a NSNumber)
        else
        {
            self.lastExit = 0;
        }
        if ([beaconStats objectForKey:@"totalLastVisitTime"])
            self.totalLastVisitTime = [[beaconStats objectForKey:@"totalLastVisitTime"] doubleValue];//double check that this is OK (store the interval as a NSNumber)
        else
        {
            self.totalLastVisitTime = 0;
        }
        if ([beaconStats objectForKey:@"longestVisitTime"])
            self.longestVisitTime = [[beaconStats objectForKey:@"longestVisitTime"] doubleValue];//double check that this is OK (store the interval as a NSNumber)
        else
        {
            self.longestVisitTime = 0;
        }
        if ([beaconStats objectForKey:@"cumulativeVisitTime"])
            self.cumulativeVisitTime = [[beaconStats objectForKey:@"cumulativeVisitTime"] doubleValue];//double check that this is OK (store the interval as a NSNumber)
        else
        {
            self.cumulativeVisitTime = 0;
        }

    
    }
    else
    {
        //time intervals set to zero will be handled as "last entry not available" as it will show up as epoch start otherwise
        self.lastEntry = 0;
        self.lastExit = 0;
        self.totalLastVisitTime = 0;
        self.longestVisitTime = 0;
        self.cumulativeVisitTime = 0;
    }
}

-(void)saveBeaconStats
{

    
    [beaconStats setObject:[NSNumber numberWithDouble:self.lastEntry] forKey:@"lastEntry"];
    [beaconStats setObject:[NSNumber numberWithDouble:self.lastExit] forKey:@"lastExit"];
    [beaconStats setObject:[NSNumber numberWithDouble:self.totalLastVisitTime] forKey:@"totalLastVisitTime"];
    [beaconStats setObject:[NSNumber numberWithDouble:self.longestVisitTime] forKey:@"longestVisitTime"];
    [beaconStats setObject:[NSNumber numberWithDouble:self.cumulativeVisitTime] forKey:@"cumulativeVisitTime"];
    
    
    [[NSUserDefaults standardUserDefaults]
     setObject:[NSDictionary dictionaryWithDictionary:beaconStats] forKey:self.identifier];
    
}







@end
