
#import <Foundation/Foundation.h>
#import <CoreLocation/Corelocation.h>
#import <Foundation/Foundation.h>

@interface PlistManager : NSObject

+ (PlistManager *)shared;
- (NSString *)identifierForUUID:(NSUUID *) uuid;
-(NSArray *)getAvailableBeaconRegions;
-(void)loadReadableBeaconRegions;


@property (nonatomic, copy, readonly) NSArray *supportedProximityUUIDs;

@property (nonatomic, copy, readonly) NSUUID *defaultProximityUUID;
@property (nonatomic, copy, readonly) NSNumber *defaultPower;
@property (nonatomic, copy) NSArray *plistBeaconContentsArray;
@property (nonatomic, copy) NSArray *plistRegionContentsArray;
//@property (nonatomic, copy) NSArray *plistVisitedContentsArray;
//@property (nonatomic, copy, readonly) NSArray *availableBeaconRegions;

//A dictionary consisting of all the monitored beaconRegions - each with a titel, visited count and total time visited
@property (nonatomic, strong) NSArray *visitedBeaconRegions;
@property (nonatomic, copy, readonly) NSArray *regions;
@property (nonatomic, copy, readonly) NSArray *readableBeaconRegions;



@end
