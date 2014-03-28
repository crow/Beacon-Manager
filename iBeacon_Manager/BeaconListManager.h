
#import <Foundation/Foundation.h>
#import <CoreLocation/Corelocation.h>
#import <Foundation/Foundation.h>

@interface BeaconListManager : NSObject <NSURLConnectionDelegate>

-(NSString *)identifierForUUID:(NSUUID *) uuid;
-(NSArray *)getAvailableBeaconRegionsList;

-(void)loadReadableBeaconRegions;

//Plist loading
-(void)loadLocalPlist;
-(void)loadHostedPlistWithUrl:(NSURL*)url;

@property (nonatomic, copy, readonly) NSArray *availableBeaconRegionsList;
@property (nonatomic, copy, readonly) NSArray *readableBeaconRegions;

@end
