
#import <Foundation/Foundation.h>
#import <CoreLocation/Corelocation.h>
#import <Foundation/Foundation.h>
#import "ManagedBeaconRegion.h"

@interface PlistManager : NSObject

+ (PlistManager *)shared;
- (NSString *)identifierForUUID:(NSUUID *) uuid;
-(NSArray *)getAvailableBeaconRegions;
-(void)loadRegions;
-(void)loadReadableBeaconRegions;


@property (nonatomic, copy, readonly) NSArray *supportedProximityUUIDs;

@property (nonatomic, copy, readonly) NSUUID *defaultProximityUUID;
@property (nonatomic, copy, readonly) NSNumber *defaultPower;
@property (nonatomic, copy) NSArray *plistBeaconContentsArray;
@property (nonatomic, copy) NSArray *plistRegionContentsArray;
//@property (nonatomic, copy) NSArray *plistVisitedContentsArray;
//@property (nonatomic, copy, readonly) NSArray *availableBeaconRegions;

//A dictionary consisting of all the monitored beaconRegions - each with a title, visited count and total time visited
@property (nonatomic, strong) NSArray *visitedBeaconRegions;

//available regions are regions defined in a local or remote plist
@property (nonatomic, copy, readonly) NSArray *availableRegions;
@property (nonatomic, copy, readonly) NSArray *readableBeaconRegions;



@end
