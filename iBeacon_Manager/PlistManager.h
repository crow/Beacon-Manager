
#import <Foundation/Foundation.h>
#import <CoreLocation/Corelocation.h>
#import <Foundation/Foundation.h>
#import "ManagedBeaconRegion.h"

@interface PlistManager : NSObject

+ (PlistManager *)shared;
- (NSString *)identifierForUUID:(NSUUID *) uuid;
-(NSArray *)loadAvailableBeaconRegions;
-(void)loadReadableBeaconRegions;
-(void)loadHostedPlistFromUrl:(NSURL*)url;

@property (nonatomic, copy, readonly) NSArray *availableRegions;
@property (nonatomic, copy, readonly) NSArray *readableBeaconRegions;



@end
