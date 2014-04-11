/*
 Copyright 2009-2013 Urban Airship Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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


#define kLocalPlistFileName @"SampleBeaconRegions"

@interface BeaconListManager ()

//@property (nonatomic, strong) NSArray *plistBeaconContentsArray;
//@property (nonatomic, strong) NSArray *remoteBeaconContentsArray;
@property(nonatomic, strong) UAHTTPRequestEngine *requestEngine;


@end


@implementation BeaconListManager

- (id)init {
    self = [super init];
    if (self) {
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

- (void)loadLocalPlist {
    //initialize with local list
    NSString *plistBeaconRegionsPath = [[NSBundle mainBundle] pathForResource:kLocalPlistFileName ofType:@"plist"];
    NSArray *beaconRegionsDictArray = [[NSArray alloc] initWithContentsOfFile:plistBeaconRegionsPath];
    [self buildBeaconRegionDataFromBeaconDictArray:beaconRegionsDictArray];
}

- (void)loadHostedPlistWithUrl:(NSURL *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self buildBeaconRegionDataFromBeaconDictArray:[[NSArray alloc] initWithContentsOfURL:url]];
    });
}

-(void)loadRemoteListWithUrl:(NSURL *)url{
    //intialize the connection with the request
    [self retrieveBeaconListOnSuccess:^(NSMutableArray *beaconRegions) {
        UA_LTRACE(@"Request to retrieve beacon list succeeded");
        
        
    } onFailure:^(UAHTTPRequest *request) {
        UA_LTRACE(@"Request to retrieve beacon list failed");
        
    }];
    
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
             //create the beacon region after a simple null check on the required items
             if ([beaconRegion valueForKey:@"identifier"] && [beaconRegion valueForKey:@"uuid"] && [beaconRegion valueForKey:@"major"] && [beaconRegion valueForKey:@"minor"]) {
                 beaconID = [[NSString alloc] initWithString:[beaconRegion valueForKey:@"identifier"]];
                 beaconProximityUUID = [[NSUUID alloc] initWithUUIDString:[beaconRegion valueForKey:@"uuid"]];
                 beaconMajor = [[beaconRegion valueForKey:@"major"] doubleValue];
                 beaconMinor = [[beaconRegion valueForKey:@"minor"] doubleValue];
                 CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconProximityUUID major:beaconMajor minor:beaconMinor identifier:beaconID];
                 [beaconRegionsArray addObject:beaconRegion];
             }
             else
             {
                 NSLog(@"Beacon list is missing a key (should have: identifier, uuid, major, minor)");
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

//- (NSArray *)buildBeaconRegionDataFromPlist {
//    NSMutableArray *beaconRegions = [NSMutableArray array];
//    for (NSDictionary *beaconDict in _plistBeaconContentsArray) {
//        CLBeaconRegion *beaconRegion = [self mapDictionaryToBeacon:beaconDict];
//        [beaconRegions addObject:beaconRegion];
//    }
//    return [NSArray arrayWithArray:beaconRegions];
//}

- (NSArray *)buildBeaconRegionDataFromBeaconDictArray:(NSArray *) beaconDictArray
{
    NSMutableArray *beaconRegions = [NSMutableArray array];
    for (NSDictionary *beaconDict in beaconDictArray) {
        CLBeaconRegion *beaconRegion = [self mapDictionaryToBeacon:beaconDict];
        
        if (beaconRegion)
            [beaconRegions addObject:beaconRegion];
        else
            NSLog(@"beaconRegion is returning null from mapDictionaryToBeacon");
    }
    
    //set availabe beacon region list with last loaded beacon regions list
    _availableBeaconRegionsList = [NSArray arrayWithArray:beaconRegions];
    
    return [NSArray arrayWithArray:beaconRegions];
}


// maps each plist dictionary representing a beacon region to an allocated beacon region
- (CLBeaconRegion *)mapDictionaryToBeacon:(NSDictionary *)dictionary {
    
    NSUUID *proximityUUID;
    CLBeaconMajorValue major = 0;
    CLBeaconMajorValue minor = 0;
    NSString *identifier;
    
    if (dictionary) {
        if ([dictionary valueForKey:@"uuid"] && [[dictionary valueForKey:@"uuid"] isKindOfClass:[NSString class]]) {
            proximityUUID = [[NSUUID alloc] initWithUUIDString:[dictionary valueForKey:@"uuid"]];
        }
        
        if ([dictionary valueForKey:@"major"] && [[dictionary valueForKey:@"major"] isKindOfClass:[NSNumber class]]) {
            major = [[dictionary valueForKey:@"major"] unsignedShortValue];
        }
        
        if ([dictionary valueForKey:@"minor"] && [[dictionary valueForKey:@"minor"] isKindOfClass:[NSNumber class]]) {
            minor = [[dictionary valueForKey:@"minor"] unsignedShortValue];
        }
        
        if ([dictionary valueForKey:@"identifier"] && [[dictionary valueForKey:@"identifier"] isKindOfClass:[NSString class]]) {
            identifier = [dictionary valueForKey:@"identifier"];
        }
        
    } else {
        proximityUUID = [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
        major = 0;
        minor = 0;
        identifier = @"No Identifier";
    }
    
    return [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:major minor:minor identifier:identifier];
}

#pragma non-essential helper methods
//- (NSString *)identifierForUUID:(NSUUID *) uuid {
//    
//    if (self.readableBeaconRegions) {
//        for (NSString *string in self.readableBeaconRegions) {
//            //if string contains - <UUID> then remove this portion so only the identifier remains
//            NSString *uuidPortion = [NSString stringWithFormat:@" - %@", [uuid UUIDString]];
//            
//            if ([string rangeOfString:[uuid UUIDString]].location != NSNotFound) {
//                return [string substringToIndex:[string rangeOfString:uuidPortion].location];
//            }
//        }
//        //uuid is not in the monitored list
//        return nil;
//    }
//    
//    //identifer for UUID did not return (╯°□°)╯︵ ┻━┻
//    return nil;
//}

@end

