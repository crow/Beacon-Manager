//
//  ManagedBeaconRegion.h
//  iBeacon_Manager
//
//  Created by David Crow on 11/15/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface ManagedBeaconRegion : CLBeaconRegion

//every beacon region has at least 1 ibeacon that represents it TODO:expand for case of multiple beacons for one region
@property (nonatomic, strong) CLBeacon *beacon;

@property (nonatomic, strong, readonly) NSDictionary *beaconStats;

@property int visits;
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
