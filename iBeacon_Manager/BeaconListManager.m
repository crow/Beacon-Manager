#import "BeaconListManager.h"
#import "UAHTTPConnection.h"
#import "UAUtils.h"

#import "UAHTTPRequest.h"
#import "UAirship.h"
#import "UAPush.h"
#import "UAHTTPRequestEngine.h"
#import "UALocationService.h"
#import "BeaconRegionManager.h"

typedef void (^UAInboxClientSuccessBlock)(void);
typedef void (^UAInboxClientRetrievalSuccessBlock)(NSMutableArray *beaconRegions);
typedef void (^UAInboxClientFailureBlock)(UAHTTPRequest *request);

@interface BeaconListManager ()

@property (nonatomic, strong) NSArray *beaconContentsArray;
@property (nonatomic, strong) NSArray *remoteBeaconContentsArray;
@property(nonatomic, strong) UAHTTPRequestEngine *requestEngine;

@end

@implementation BeaconListManager
{
    NSFileManager *_manager;
    NSArray *_uuidToTitleKey;
    NSArray *_availableBeaconRegions;
    NSArray *_beaconContentsArray;
    NSArray *_regionContentsArray;
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
    
    UALocationService *locationService = [[UAirship shared] locationService];
    [locationService startReportingSignificantLocationChanges];
    
    
    // locationManager update as location
    [[BeaconRegionManager shared] locationManager].desiredAccuracy = kCLLocationAccuracyBest;
    [[BeaconRegionManager shared] locationManager].distanceFilter = kCLDistanceFilterNone;
    [[[BeaconRegionManager shared] locationManager] startUpdatingLocation];
    [[[BeaconRegionManager shared] locationManager] stopUpdatingLocation];
    CLLocation *location = [[[BeaconRegionManager shared] locationManager] location];
    // Configure the new event with information from the location
    float longitude=location.coordinate.longitude;
    float latitude=location.coordinate.latitude;
    
    NSLog(@"dLongitude : %f", longitude);
    NSLog(@"dLatitude : %f", latitude);
    
    NSString *urlString = [NSString stringWithFormat: @"%@%f%@%f", @"https://proserve-test.urbanairship.com:1443/ibeacons?lat=", latitude, @"&long=", longitude];
    //                    @"https://proserve-test.urbanairship.com:1443/ibeacons?lat=45.53207&long=-122.69879'"];
    NSURL *requestUrl = [NSURL URLWithString: urlString];
    NSLog(@"request url : %@", urlString);
    UAHTTPRequest *request = [UAUtils UAHTTPUserRequestWithURL:requestUrl method:@"GET"];
    
    //TODO don't hardcode these
    request.username = @"V6a5HDxsRl-9yuDhgj4WHg";
    request.password = @"NYT-ZbPdRVeVFkgk9-rBKA";
    
    
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
         NSArray *jsonResponse = [BeaconListManager objectWithString:responseString];
         UA_LTRACE(@"Retrieved message list response: %@", responseString);
         
         NSArray *beaconRegionsList;

         if ([jsonResponse isKindOfClass:[NSArray class]])
         {
             beaconRegionsList = jsonResponse;
         }
         else
         {
             NSLog(@"JSON response is not an array of beacons!");
         }
     
         _beaconContentsArray = [[NSArray alloc] initWithArray:beaconRegionsList];
         [self buildAndLoadAvailableBeaconRegionsList];
         
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
    _beaconContentsArray = [[NSArray alloc] initWithContentsOfFile:plistBeaconRegionsPath];
    
    [self buildAndLoadAvailableBeaconRegionsList];
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
        _beaconContentsArray = [[NSArray alloc] initWithContentsOfURL:url];
        [self buildAndLoadAvailableBeaconRegionsList];
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
    for(NSDictionary *beaconDict in _beaconContentsArray)
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
