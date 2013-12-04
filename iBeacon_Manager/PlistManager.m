#import "PlistManager.h"

@implementation PlistManager {
    NSFileManager* manager;
    NSArray *uuidToTitleKey;
    NSArray *availableBeaconRegions;
    
    NSArray *plistBeaconContentsArray;
    NSArray *plistRegionContentsArray;
}

- (id)init
{
    self = [super init];
    
    if(self)
    {
//        //Initialize plist filed - TODO add file mngr checking
//        [self getAvailableManagedBeaconRegions];
    }
    
    return self;
}

-(void)loadSampleLists
{
    //Initialize plist filed - TODO add file mngr checking
    manager = [NSFileManager defaultManager];
    NSString* plistRegionsPath = [[NSBundle mainBundle] pathForResource:@"Regions" ofType:@"plist"];
    plistRegionContentsArray = [NSArray arrayWithContentsOfFile:plistRegionsPath];
    
    
    //initialize with local list
    NSString* plistBeaconRegionsPath = [[NSBundle mainBundle] pathForResource:@"BeaconRegions" ofType:@"plist"];
    plistBeaconContentsArray = [[NSArray alloc] initWithContentsOfFile:plistBeaconRegionsPath];
    
    [self loadAvailableManagedBeaconRegions];
}

-(NSArray*)getAvailableManagedBeaconRegions
{
    //set read-only available regions 
    [self loadAvailableManagedBeaconRegions];
    return self.availableManagedBeaconRegions;
}

-(void)loadHostedPlistFromUrl:(NSURL*)url
{
    //
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        plistBeaconContentsArray = [[NSArray alloc] initWithContentsOfURL:url];
        [self getAvailableManagedBeaconRegions];
        [self loadReadableBeaconRegions];
        
    });
}

-(void)loadAvailableManagedBeaconRegions
{
    _availableManagedBeaconRegions = [self buildBeaconRegionDataFromPlist];
}

//This is a helper method that can be removed, useful for displaying IDs next to UUID
-(void)loadReadableBeaconRegions
{
    
    NSMutableArray *readableBeaconArray = [[NSMutableArray alloc] initWithCapacity:[self.availableManagedBeaconRegions count]];
    NSString *currentReadableBeacon = [[NSString alloc] init];
    
    for (ManagedBeaconRegion *beaconRegion in availableBeaconRegions)
    {
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
        for (NSString *string in self.readableBeaconRegions)
        {
            //if string contains - <UUID> then remove this portion so only the identifier remains
            NSString *uuidPortion = [NSString stringWithFormat:@" - %@", [uuid UUIDString]];
            //NSRange returns a struct, so make sure it isn't nil, TODO:add nil check
            
            if (string != nil)
            {
                uuidRange = [string rangeOfString:[uuid UUIDString]];
            }
            if (uuidRange.location != NSNotFound)
            {
                return [string substringToIndex:[string rangeOfString:uuidPortion].location];
            }
        }
        //uuid is not in the monitored list
        return nil;
    }
    
    //identifer for UUID did not return (╯°□°)╯︵ ┻━┻
    return nil;
}


- (NSArray*) buildBeaconRegionDataFromPlist
{
    NSMutableArray *managedBeaconRegions = [NSMutableArray array];
    for(NSDictionary *beaconDict in plistBeaconContentsArray)
    {
        ManagedBeaconRegion *beaconRegion = [self mapDictionaryToBeacon:beaconDict];
        if (beaconRegion != nil) {
              [managedBeaconRegions addObject:beaconRegion];
        }
    }
    return [NSArray arrayWithArray:managedBeaconRegions];
}



//maps each plist dictionary representing a managed beacon region to a managed beacon region
- (ManagedBeaconRegion*)mapDictionaryToBeacon:(NSDictionary*)dictionary
{
    NSUUID *proximityUUID;
    short major= 0;
    short minor = 0;
    NSString *identifier;
    
    if (dictionary){
        if ([dictionary valueForKey:@"proximityUUID"] != nil && [[dictionary valueForKey:@"proximityUUID"]isKindOfClass:[NSString class]])
        {
           proximityUUID = [[NSUUID alloc] initWithUUIDString:[dictionary valueForKey:@"proximityUUID"]];
        }
        
        if ([dictionary valueForKey:@"Major"] != nil && [[dictionary valueForKey:@"Major"]isKindOfClass:[NSNumber class]])
        {
            major = [[dictionary valueForKey:@"Major"] shortValue];
        }
        if ([dictionary valueForKey:@"Minor"] != nil && [[dictionary valueForKey:@"Minor"]isKindOfClass:[NSNumber class]])
        {
            minor = [[dictionary valueForKey:@"Minor"] shortValue];
        }
        if ([dictionary valueForKey:@"title"] != nil && [[dictionary valueForKey:@"title"]isKindOfClass:[NSString class]]) {
            identifier = [dictionary valueForKey:@"title"];
        }
     
    }
    else
    {
        proximityUUID = [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
        major = 000;
        minor = 000;
        identifier = @"No Identifier";
    }
    //return [[ManagedBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:identifier];

    return [[ManagedBeaconRegion alloc] initWithProximityUUID:proximityUUID major:major minor:minor identifier:identifier];
}

#pragma regions support TODOs

//TODO: add regions support in separate plist
/*
- (NSArray*) buildRegionsDataFromPlist
{
    NSMutableArray *regions = [NSMutableArray array];
    for(NSDictionary *regionDict in plistRegionContentsArray)
    {
        CLRegion *region = [self mapDictionaryToRegion:regionDict];
        
        if (region != nil) {
            [regions addObject:region];
        }
    }
    return [NSArray arrayWithArray:regions];
}

- (CLRegion*)mapDictionaryToRegion:(NSDictionary*)dictionary
{
    NSString *title = [dictionary valueForKey:@"title"];
    
    CLLocationDegrees latitude = [[dictionary valueForKey:@"latitude"] doubleValue];
    CLLocationDegrees longitude = [[dictionary valueForKey:@"longitude"] doubleValue];
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    CLLocationDistance regionRadius = [[dictionary valueForKey:@"radius"] doubleValue];
    return [[CLRegion alloc] initCircularRegionWithCenter:centerCoordinate radius:regionRadius identifier:title];
    
}
*/
@end
