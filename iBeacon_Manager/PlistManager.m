#import "PlistManager.h"

@implementation PlistManager {
    NSFileManager* manager;
    NSArray *uuidToTitleKey;
    NSArray *availableBeaconRegions;
}

- (id)init
{
    self = [super init];
    if(self)
    {

        //Initialize plist filed - TODO add file mngr checking
        manager = [NSFileManager defaultManager];
        NSString* plistRegionsPath = [[NSBundle mainBundle] pathForResource:@"Regions" ofType:@"plist"];
        _plistRegionContentsArray = [NSArray arrayWithContentsOfFile:plistRegionsPath];
        
        NSString* plistBeaconRegionsPath = [[NSBundle mainBundle] pathForResource:@"BeaconRegions" ofType:@"plist"];
        self.plistBeaconContentsArray = [[NSArray alloc] initWithContentsOfFile:plistBeaconRegionsPath];
        
        availableBeaconRegions = [[NSArray alloc] initWithArray:[self getAvailableBeaconRegions]];
        _regions = [self buildRegionsDataFromPlist];
        
    }
    
    return self;
}

+ (PlistManager *)shared
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

-(NSArray *)getAvailableBeaconRegions{
    return [self buildBeaconsDataFromPlist];
}

-(void)loadReadableBeaconRegions{
    
    NSMutableArray *readableBeaconArray = [[NSMutableArray alloc] initWithCapacity:[availableBeaconRegions count]];
    NSString *currentReadableBeacon = [[NSString alloc] init];
    
    for (ManagedBeaconRegion *beaconRegion in availableBeaconRegions) {
        currentReadableBeacon = [NSString stringWithFormat:@"%@ - %@", [beaconRegion identifier], [[beaconRegion proximityUUID] UUIDString]];
        [readableBeaconArray addObject:currentReadableBeacon];
    }
    
    _readableBeaconRegions = [NSArray arrayWithArray:readableBeaconArray];
}

-(NSString *)identifierForUUID:(NSUUID *) uuid
{
    NSRange uuidRange;
    if (self.readableBeaconRegions != nil)
    {
        for (NSString *string in self.readableBeaconRegions) {
            //if string contains - <UUID> then remove this portion so only the identifier remains
            NSString *uuidPortion = [NSString stringWithFormat:@" - %@", [uuid UUIDString]];
            //NSRange returns a struct, so make sure it isn't nil, TODO:add nil check
            
            if (string != nil)
                uuidRange = [string rangeOfString:[uuid UUIDString]];
            
            if (uuidRange.location != NSNotFound){
                return [string substringToIndex:[string rangeOfString:uuidPortion].location];
            }
        }
        NSLog(@"uuid is not in the monitored list (╯°□°)╯︵ ┻━┻");
        return nil;
    }
    
    NSLog(@"identifer for UUID did not return (╯°□°)╯︵ ┻━┻");
    return nil;
}


- (NSArray*) buildBeaconsDataFromPlist
{
    NSMutableArray *beacons = [NSMutableArray array];
    for(NSDictionary *beaconDict in self.plistBeaconContentsArray)
    {
        ManagedBeaconRegion *beaconRegion = [self mapDictionaryToBeacon:beaconDict];
        if (beaconRegion != nil) {
              [beacons addObject:beaconRegion];
        } else {
            NSLog(@"beaconRegion is nil (╯°□°)╯︵ ┻━┻");
        }
     
    }
    
    return [NSArray arrayWithArray:beacons];
}

- (NSArray*) buildRegionsDataFromPlist
{
    NSMutableArray *regions = [NSMutableArray array];
    for(NSDictionary *regionDict in _plistRegionContentsArray)
    {
        CLRegion *region = [self mapDictionaryToRegion:regionDict];
        
        if (region != nil) {
            [regions addObject:region];
        } else {
            NSLog(@"region is nil (╯°□°)╯︵ ┻━┻");
        }
        
    }
    return [NSArray arrayWithArray:regions];
}

- (ManagedBeaconRegion*)mapDictionaryToBeacon:(NSDictionary*)dictionary {
    NSString *title = [dictionary valueForKey:@"title"];
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:[dictionary valueForKey:@"proximityUUID"]];
    //short minor = 11;
    //short major = 1111;
    
    //return [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:major minor:minor identifier:title];

    return [[ManagedBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:title];
}

- (CLRegion*)mapDictionaryToRegion:(NSDictionary*)dictionary {
    NSString *title = [dictionary valueForKey:@"title"];
    
    CLLocationDegrees latitude = [[dictionary valueForKey:@"latitude"] doubleValue];
    CLLocationDegrees longitude = [[dictionary valueForKey:@"longitude"] doubleValue];
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    CLLocationDistance regionRadius = [[dictionary valueForKey:@"radius"] doubleValue];
    return [[CLRegion alloc] initCircularRegionWithCenter:centerCoordinate radius:regionRadius identifier:title];
    
}

@end
