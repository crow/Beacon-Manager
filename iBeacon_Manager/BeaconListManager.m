/*
 Copyright 2009-2013 Urban Airship Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BeaconListManager.h"
#import "UAirship.h"
#import "UAPush.h"
#import "BeaconRegionManager.h"



#define kLocalPlistFileName @"SampleBeaconRegions"

@interface BeaconListManager ()

@end

@implementation BeaconListManager

- (id)init {
    self = [super init];
    if (self) {
    }
    
    return self;
}

+ (id)objectWithString:(NSString *)jsonString {
    if (!jsonString) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData: [jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                           options: NSJSONReadingMutableContainers
                                             error: nil];
}

#pragma load last list
- (void)loadLastMonitoredList {
    //set the availableBeaconRegions list
    _availableBeaconRegionsList = [[[[BeaconRegionManager shared] locationManager] monitoredRegions] allObjects];
}

#pragma QR code list loading
-(void)loadSingleBeaconRegion:(CLBeaconRegion * ) beaconRegion{
    _availableBeaconRegionsList = [[NSArray alloc] initWithObjects:beaconRegion, nil];
    [[[BeaconRegionManager shared] beaconRegionManagerDelegate] qRBasedListFinishedLoadingWithList:[[NSArray alloc] initWithObjects:beaconRegion, nil]];
}

-(void)loadBeaconRegionsArray:(NSArray *) beaconRegions{
    _availableBeaconRegionsList = [[NSArray alloc] initWithArray:beaconRegions];
    [[[BeaconRegionManager shared] beaconRegionManagerDelegate] qRBasedListFinishedLoadingWithList:beaconRegions];
}


#pragma local list/sample plist loading
- (void)loadLocalPlist {
    //initialize with local list
    NSString *plistBeaconRegionsPath = [[NSBundle mainBundle] pathForResource:kLocalPlistFileName ofType:@"plist"];
    NSArray *beaconRegionsDictArray = [[NSArray alloc] initWithContentsOfFile:plistBeaconRegionsPath];
    
    //build the beacon regions data from the dict array (and set available regions in the list manager) and set the availableBeaconRegions list
    _availableBeaconRegionsList = [NSArray arrayWithArray:[self buildBeaconRegionDataFromBeaconDictArray:beaconRegionsDictArray]];
    
    //make the delegate callback
    [[[BeaconRegionManager shared] beaconRegionManagerDelegate] localListFinishedLoadingWithList:beaconRegionsDictArray];
}

#pragma list parsing helpers
- (NSArray *)buildBeaconRegionDataFromBeaconDictArray:(NSArray *) beaconDictArray{
    NSMutableArray *beaconRegions = [NSMutableArray array];
    for (NSDictionary *beaconDict in beaconDictArray) {
        CLBeaconRegion *beaconRegion = [self mapDictionaryToBeacon:beaconDict];
        
        if (beaconRegion)
            [beaconRegions addObject:beaconRegion];
        else
            NSLog(@"beaconRegion is returning null from mapDictionaryToBeacon");
    }
    
    //set availabe beacon region list with last loaded beacon regions list
    _availableBeaconRegionsList = [NSArray arrayWithArray:beaconRegions];
    
    return [NSArray arrayWithArray:beaconRegions];
}

// maps each plist dictionary representing a beacon region to an allocated beacon region
- (CLBeaconRegion *)mapDictionaryToBeacon:(NSDictionary *)dictionary{
    
    NSUUID *proximityUUID;
    CLBeaconMajorValue major = 0;
    CLBeaconMajorValue minor = 0;
    NSString *identifier;
    
    if (dictionary) {
        if ([dictionary valueForKey:@"uuid"] && [[dictionary valueForKey:@"uuid"] isKindOfClass:[NSString class]]) {
            proximityUUID = [[NSUUID alloc] initWithUUIDString:[dictionary valueForKey:@"uuid"]];
        }
        
        if ([dictionary valueForKey:@"major"] && [[dictionary valueForKey:@"major"] isKindOfClass:[NSNumber class]]) {
            major = [[dictionary valueForKey:@"major"] unsignedShortValue];
        }
        
        if ([dictionary valueForKey:@"minor"] && [[dictionary valueForKey:@"minor"] isKindOfClass:[NSNumber class]]) {
            minor = [[dictionary valueForKey:@"minor"] unsignedShortValue];
        }
        
        if ([dictionary valueForKey:@"identifier"] && [[dictionary valueForKey:@"identifier"] isKindOfClass:[NSString class]]) {
            identifier = [dictionary valueForKey:@"identifier"];
        }
        
    } else {
        proximityUUID = [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
        major = 0;
        minor = 0;
        identifier = @"NoIdentifier";
    }
    
    return [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:major minor:minor identifier:identifier];
}

@end

