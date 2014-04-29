
#import <Foundation/Foundation.h>
#import <CoreLocation/Corelocation.h>
#import <Foundation/Foundation.h>

@interface BeaconListManager : NSObject <NSURLConnectionDelegate>

@property (nonatomic, copy, readonly) NSArray *availableBeaconRegionsList;

//List loading
-(void)loadLastMonitoredList;
-(void)loadLocalPlist;
-(void)loadLocationBasedList;
-(void)loadHostedPlistWithUrl:(NSURL*)url;
-(void)loadSingleBeaconRegion:(CLBeaconRegion * ) beaconRegion;
-(void)loadBeaconRegionsArray:(NSArray *) beaconRegions;


@end
