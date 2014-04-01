#import "BeaconListManager.h"
#import "UAHTTPConnection.h"
#import "UAUtils.h"

#import "UAHTTPRequest.h"
#import "UAirship.h"
#import "UAPush.h"
#import "UAHTTPRequestEngine.h"

typedef void (^UAInboxClientSuccessBlock)(void);
typedef void (^UAInboxClientRetrievalSuccessBlock)(NSMutableArray *beaconRegions);
typedef void (^UAInboxClientFailureBlock)(UAHTTPRequest *request);

@interface BeaconListManager ()

@property (nonatomic, strong) NSArray *plistBeaconContentsArray;
@property (nonatomic, strong) NSArray *remoteBeaconContentsArray;
@property(nonatomic, strong) UAHTTPRequestEngine *requestEngine;

@end

@implementation BeaconListManager
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
        self.requestEngine = [[UAHTTPRequestEngine alloc] init];
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

-(NSArray*)getAvailableBeaconRegionsList
{
    
    //THIS SHOULDN'T BE BUILDING AND LOADING
    //set read-only available regions
    //[self buildAndLoadAvailableBeaconRegionsList];
    return self.availableBeaconRegionsList;
}

//curl -i -u 'zuhKEYkfT4ys-CAix4fWFg:R28JlFrvQ-KzTbW_-DUEpw' 'https://proserve-test.urbanairship.com:1443/ibeacons?lat=45.53207&long=-122.69879'

- (UAHTTPRequest *)locationListRequest{
    //NSString *urlString = [NSString stringWithFormat: @"%@%@",
    //                    @"https://proserve-test.urbanairship.com:1443/ibeacons?lat=45.53207&long=-122.69879'"];
    NSURL *requestUrl = [NSURL URLWithString: @"https://proserve-test.urbanairship.com:1443/ibeacons?lat=45.53207&long=-122.69879"];
    
    UAHTTPRequest *request = [UAUtils UAHTTPUserRequestWithURL:requestUrl method:@"GET"];
    request.username = @"zuhKEYkfT4ys-CAix4fWFg";
    request.password = @"R28JlFrvQ-KzTbW_-DUEpw";
    
    //UA_LTRACE(@"Request to retrieve beacon list: %@", urlString);
    
    return request;
}

//expects to receive a dictionary titled "beaconRegions" (JSON) that has a dictionary for each individual beacon, returns beacon array
- (void)retrieveBeaconListOnSuccess:(UAInboxClientRetrievalSuccessBlock)successBlock
                          onFailure:(UAInboxClientFailureBlock)failureBlock {
    
    UAHTTPRequest *listRequest = [self locationListRequest];
    
    [self.requestEngine
     runRequest:listRequest
     succeedWhere:^(UAHTTPRequest *request){
         return (BOOL)(request.response.statusCode == 200);
     } retryWhere:^(UAHTTPRequest *request){
         return NO;
     } onSuccess:^(UAHTTPRequest *request, NSUInteger lastDelay){
         
         NSString *responseString = request.responseString;
         NSDictionary *jsonResponse = [BeaconListManager objectWithString:responseString];
         UA_LTRACE(@"Retrieved message list response: %@", responseString);
         
         NSDictionary *beaconRegionsList;
//         
//         NSString *beaconID;
//         NSUUID *beaconProximityUUID;
//         double beaconMajor;
//         double beaconMinor;
//         
//         NSMutableArray *beaconRegionsArray = [[NSMutableArray alloc] init];
//         
         
         //check to see if the json response is an array
         if ([jsonResponse isKindOfClass:[NSArray class]])
         {
             beaconRegionsList = jsonResponse;
         }
         else
         {
             NSLog(@"JSON response is not an array of beacons!");
         }
         
         // Convert dictionary to objects for both convenience and necessity
//         for (NSDictionary *beaconRegion in beaconRegionsList)
//         {
//             if ([beaconRegion valueForKey:@"identifier"]) {
//                 beaconID = [[NSString alloc] initWithString:[beaconRegion valueForKey:@"identifier"]];
//             }
//             if ([beaconRegion valueForKey:@"uuid"]) {
//                 beaconProximityUUID = [[NSUUID alloc] initWithUUIDString:@"E53D412B-776B-4F56-8061-9A13535BD34A"];
//             }
//             if ([beaconRegion valueForKey:@"major"]) {
//                 beaconMajor = [[beaconRegion valueForKey:@"major"] doubleValue];
//             }
//             if ([beaconRegion valueForKey:@"minor"]) {
//                 beaconMinor = [[beaconRegion valueForKey:@"minor"] doubleValue];
//             }
//             
//             //create the beacon region after a simple null check on the required items
//             if (beaconID && beaconProximityUUID && beaconMajor && beaconMinor) {
//                 CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconProximityUUID major:beaconMajor minor:beaconMinor identifier:beaconID];
//                 [beaconRegionsArray addObject:beaconRegion];
//             }
//             else
//             {
//                 NSLog(@"Beacon list is missing contents/nidentifier:%@, uuid:%@, major:%f, minor:%f", beaconID, beaconProximityUUID, beaconMajor, beaconMinor);
//             }
//             
//         }
         
         //load beacon regions array into beacon list manager
         
     
         _plistBeaconContentsArray = [[NSArray alloc] initWithArray:beaconRegionsList];
         [self buildAndLoadAvailableBeaconRegionsList];
         [self loadReadableBeaconRegions];
         
         if (successBlock) {
             
         } else {
             UA_LERR(@"missing successBlock");
         }
         
     } onFailure:^(UAHTTPRequest *request, NSUInteger lastDelay){
         if (failureBlock) {
             failureBlock(request);
         } else {
             UA_LERR(@"missing failureBlock");
         }
     }];
}

-(void)loadLocalPlist
{
    //initialize with local list
    NSString* plistBeaconRegionsPath = [[NSBundle mainBundle] pathForResource:@"SampleBeaconRegions" ofType:@"plist"];
    _plistBeaconContentsArray = [[NSArray alloc] initWithContentsOfFile:plistBeaconRegionsPath];
    
    [self buildAndLoadAvailableBeaconRegionsList];
    [self loadReadableBeaconRegions];
}

-(void)loadLocationBasedList
{
    //intialize the connection with the request
    [self retrieveBeaconListOnSuccess:^(NSMutableArray *beaconRegions) {
        UA_LTRACE(@"Request to retrieve beacon list succeeded");
        
        
    } onFailure:^(UAHTTPRequest *request) {
        UA_LTRACE(@"Request to retrieve beacon list failed");
        
    }];
}

-(void)loadHostedPlistWithUrl:(NSURL*)url
{
  //TODO make a sane URL request with a callback instead of this bullshit
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        _plistBeaconContentsArray = [[NSArray alloc] initWithContentsOfURL:url];
        [self buildAndLoadAvailableBeaconRegionsList];
        [self loadReadableBeaconRegions];
        
    });
}


-(void)buildAndLoadAvailableBeaconRegionsList
{
    _availableBeaconRegionsList = [self buildBeaconRegionsFromBeaconDictionaries];
}


//takes an nsarray of ibeacon dictionaries and returns an array of CLBeacon objects
- (NSArray*) buildBeaconRegionsFromBeaconDictionaries
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
        if ([dictionary valueForKey:@"uuid"] != nil && [[dictionary valueForKey:@"uuid"]isKindOfClass:[NSString class]])
        {
           proximityUUID = [[NSUUID alloc] initWithUUIDString:[dictionary valueForKey:@"uuid"]];
        }
        if ([dictionary valueForKey:@"major"] != nil && [[dictionary valueForKey:@"major"]isKindOfClass:[NSNumber class]])
        {
            major = [[dictionary valueForKey:@"major"] shortValue];
        }
        if ([dictionary valueForKey:@"minor"] != nil && [[dictionary valueForKey:@"minor"]isKindOfClass:[NSNumber class]])
        {
            minor = [[dictionary valueForKey:@"minor"] shortValue];
        }
        if ([dictionary valueForKey:@"identifier"] != nil && [[dictionary valueForKey:@"identifier"]isKindOfClass:[NSString class]]) {
            identifier = [dictionary valueForKey:@"identifier"];
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
