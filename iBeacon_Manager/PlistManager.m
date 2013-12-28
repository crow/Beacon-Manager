#import "PlistManager.h"


@implementation PlistManager
{
    NSFileManager *_manager;
    NSArray *_uuidToTitleKey;
    NSArray *_availableBeaconRegions;
    NSArray *_plistBeaconContentsArray;
    NSArray *_plistRegionContentsArray;
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



-(NSArray*)getAvailableBeaconRegionsList
{
    //set read-only available regions 
    [self loadAvailableBeaconRegionsList];
    return self.availableBeaconRegionsList;
}

-(void)loadLocalPlist
{
    //initialize with local list
    NSString* plistBeaconRegionsPath = [[NSBundle mainBundle] pathForResource:@"CKO" ofType:@"plist"];
    _plistBeaconContentsArray = [[NSArray alloc] initWithContentsOfFile:plistBeaconRegionsPath];
    
    [self loadAvailableBeaconRegionsList];
    [self loadReadableBeaconRegions];
}

-(void)loadHostedPlistWithUrl:(NSURL*)url
{
    //
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        _plistBeaconContentsArray = [[NSArray alloc] initWithContentsOfURL:url];
        [self getAvailableBeaconRegionsList];
        [self loadReadableBeaconRegions];
        
    });
}

-(void)loadAvailableBeaconRegionsList
{
    _availableBeaconRegionsList = [self buildBeaconRegionDataFromPlist];
}

- (NSArray*) buildBeaconRegionDataFromPlist
{
    NSMutableArray *managedBeaconRegions = [NSMutableArray array];
    for(NSDictionary *beaconDict in _plistBeaconContentsArray)
    {
        CLBeaconRegion *beaconRegion = [self mapDictionaryToBeacon:beaconDict];
        if (beaconRegion != nil)
        {
              [managedBeaconRegions addObject:beaconRegion];
        }
    }
    return [NSArray arrayWithArray:managedBeaconRegions];
}


//maps each plist dictionary representing a managed beacon region to a managed beacon region
- (CLBeaconRegion*)mapDictionaryToBeacon:(NSDictionary*)dictionary
{
    NSUUID *proximityUUID;
    short major= 0;
    short minor = 0;
    NSString *identifier;
    
    if (dictionary)
    {
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
    return [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:major minor:minor identifier:identifier];
}

#pragma non-essential helper methods

//This is a helper method that can be removed, useful for displaying IDs next to UUID
-(void)loadReadableBeaconRegions
{
    
    NSMutableArray *readableBeaconArray = [[NSMutableArray alloc] initWithCapacity:[self.availableBeaconRegionsList count]];
    NSString *currentReadableBeacon;
    
    for (CLBeaconRegion *beaconRegion in _availableBeaconRegions)
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

@end
