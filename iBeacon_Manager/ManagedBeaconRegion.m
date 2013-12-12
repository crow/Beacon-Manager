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
}

@end
