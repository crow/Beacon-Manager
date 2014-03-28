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
    //set read-only available regions 
    [self loadAvailableBeaconRegionsList];
    return self.availableBeaconRegionsList;
}

//curl -i -u 'zuhKEYkfT4ys-CAix4fWFg:R28JlFrvQ-KzTbW_-DUEpw' 'https://proserve-test.urbanairship.com:1443/ibeacons?lat=45.53207&long=-122.69879'

- (UAHTTPRequest *)listRequest{
    NSString *urlString = [NSString stringWithFormat: @"%@%@",
                           @"https://proserve-test.urbanairship.com:1443/", @"ibeacons?lat=45.53207&long=-122.69879'"];
    NSURL *requestUrl = [NSURL URLWithString: urlString];
    
    UAHTTPRequest *request = [UAUtils UAHTTPUserRequestWithURL:requestUrl method:@"GET"];
    request.username = @"zuhKEYkfT4ys-CAix4fWFg";
    request.password = @"R28JlFrvQ-KzTbW_-DUEpw";
    
    UA_LTRACE(@"Request to retrieve beacon list: %@", urlString);
    
    return request;
}

//expects to receive a dictionary titled "beaconRegions" (JSON) that has a dictionary for each individual beacon, returns beacon array
- (void)retrieveBeaconListOnSuccess:(UAInboxClientRetrievalSuccessBlock)successBlock
                          onFailure:(UAInboxClientFailureBlock)failureBlock {
    
    UAHTTPRequest *listRequest = [self listRequest];
    
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
         
         NSString *beaconID;
         NSUUID *beaconProximityUUID;
         double beaconMajor;
         double beaconMinor;
         
         NSMutableArray *beaconRegionsArray = [NSMutableArray array];
         
         
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
         for (NSDictionary *beaconRegion in beaconRegionsList)
         {
             if ([beaconRegion valueForKey:@"identifier"]) {
                 beaconID = [[NSString alloc] initWithString:[beaconRegion valueForKey:@"identifier"]];
             }
             if ([beaconRegion valueForKey:@"uuid"]) {
                 beaconProximityUUID = [[NSUUID alloc] initWithUUIDString:[beaconRegion valueForKey:@"uuid"]];
             }
             if ([beaconRegion valueForKey:@"major"]) {
                 beaconMajor = [[beaconRegion valueForKey:@"major"] doubleValue];
             }
             if ([beaconRegion valueForKey:@"minor"]) {
                 beaconMinor = [[beaconRegion valueForKey:@"minor"] doubleValue];
             }
             
             //create the beacon region after a simple null check on the required items
             if (beaconID && beaconProximityUUID && beaconMajor && beaconMinor) {
                 CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconProximityUUID major:beaconMajor minor:beaconMinor identifier:beaconID];
                 [beaconRegionsArray addObject:beaconRegion];
             }
             else
             {
                 NSLog(@"Beacon list is missing contents/nidentifier:%@, uuid:%@, major:%f, minor:%f", beaconID, beaconProximityUUID, beaconMajor, beaconMinor);
             }
             
         }
         
         
         
         if (successBlock) {
             
             //    successBlock([[inboxDBManager getMessages] mutableCopy], (NSUInteger) unread);
             
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
    
    [self loadAvailableBeaconRegionsList];
    [self loadReadableBeaconRegions];
}

-(void)loadHostedPlistWithUrl:(NSURL*)url
{
  //TODO make a sane URL request with a callback instead of this hilarious shit
//    NSMutableData *data;
//    
//    NSURLRequest *request=[NSURLRequest requestWithURL:url
//                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
//                                          timeoutInterval:60.0];
//    
//    NSURLConnection *connection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
//    
//    if (connection) {
//        data=[NSMutableData data];
//    } else {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No connection could be made" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//        [alert show];
//    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        _plistBeaconContentsArray = [[NSArray alloc] initWithContentsOfURL:url];
        [self loadAvailableBeaconRegionsList];
        [self loadReadableBeaconRegions];
        
    });
}

#pragma NSURLConnectionDelegate callbacks

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{

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
