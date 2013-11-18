//
//  ManagedBeaconRegion.m
//  iBeacon_Manager
//
//  Created by David Crow on 11/15/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "ManagedBeaconRegion.h"

@interface ManagedBeaconRegion ()


@end

@implementation ManagedBeaconRegion {
    NSMutableDictionary *mutableBeaconStats;
}


- (id)initWithProximityUUID:(NSUUID *)proximityUUID identifier:(NSString *)identifier{
    
    self = [super initWithProximityUUID:proximityUUID identifier:identifier];
    if (self) {
        [self initManagedBeacon];
    }
    return self;
    
}

- (id)initWithProximityUUID:(NSUUID *)proximityUUID major:(CLBeaconMajorValue)major identifier:(NSString *)identifier{
    
    self = [super initWithProximityUUID:proximityUUID major:major identifier:identifier];
    if (self) {
        [self initManagedBeacon];
    }
    return self;
    
}

- (id)initWithProximityUUID:(NSUUID *)proximityUUID major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier{
    
    self = [super initWithProximityUUID:proximityUUID major:major minor:minor identifier:identifier];
    if (self) {
        [self initManagedBeacon];
    }
    return self;

}

-(void)timestampEntry{
    NSLog(@"timestamped entry");
    self.lastEntry = [[NSDate date] timeIntervalSince1970];
}

-(void)timestampExit{
    NSLog(@"timestamped exit");
    self.lastEntry = [[NSDate date] timeIntervalSince1970];
    
    //re-calculate total visit time
    self.totalLastVisitTime = self.lastExit - self.lastEntry;
}

-(void)loadBeaconStats{
    
    [[NSUserDefaults standardUserDefaults]
     objectForKey:@"beaconStats"];
}

-(void)saveBeaconStats{
   
    
//    [mutableBeaconStats setValue:self.totalLastVisitTime forKey:@"totalLastVisitTime"]
//    
//    [[NSUserDefaults standardUserDefaults]
//     setObject:self.beaconStats forKey:@"beaconStats"];

}


-(void)initManagedBeacon{
   
}

@end
