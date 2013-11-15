//
//  ManagedBeaconRegion.h
//  iBeacon_Manager
//
//  Created by David Crow on 11/15/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface ManagedBeaconRegion : CLBeaconRegion

@property int visits;
@property (nonatomic, strong) NSDate *lastEntry;
@property (nonatomic, strong) NSDate *lastExit;
@property NSTimeInterval *totalLastVisitTime;
@property NSTimeInterval *longestVisitTime;
@property NSTimeInterval *cumulativeVisitTime;

- (id)initWithProximityUUID:(NSUUID *)proximityUUID identifier:(NSString *)identifier;
- (id)initWithProximityUUID:(NSUUID *)proximityUUID major:(CLBeaconMajorValue)major identifier:(NSString *)identifier;
- (id)initWithProximityUUID:(NSUUID *)proximityUUID major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier;



@end
