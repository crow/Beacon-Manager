//
//  ManagedBeaconRegion.h
//  iBeacon_Manager
//
//  Created by David Crow on 11/15/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface ManagedBeaconRegion : CLBeaconRegion

//closest beacon matching this beaconRegion's UUID, Major, Minor - nil if none
@property (nonatomic, strong) CLBeacon *beacon;

@property (nonatomic, strong, readonly) NSDictionary *beaconStats;

@property int visits;
@property int proximity; //unknown = 0, immediate = 1, near = 2, far = 3
@property NSTimeInterval lastEntry;
@property NSTimeInterval lastExit;
@property NSTimeInterval totalLastVisitTime;
@property NSTimeInterval longestVisitTime;
@property NSTimeInterval cumulativeVisitTime;


- (id)initWithProximityUUID:(NSUUID *)proximityUUID identifier:(NSString *)identifier;
- (id)initWithProximityUUID:(NSUUID *)proximityUUID major:(CLBeaconMajorValue)major identifier:(NSString *)identifier;
- (id)initWithProximityUUID:(NSUUID *)proximityUUID major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier;

-(void)timestampEntry;
-(void)timestampExit;


@end
