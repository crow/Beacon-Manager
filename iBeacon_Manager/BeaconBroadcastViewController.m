//
//  BeaconBroadcastViewController.m
//  iBeacon_Manager
//
//  Created by David Crow on 1/20/14.
//  Copyright (c) 2014 David Crow. All rights reserved.
//

#import "BeaconBroadcastViewController.h"
@interface BeaconBroadcastViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *broadcastImage;
@property (weak, nonatomic) IBOutlet UISwitch *broadcastSwitch;
@property (weak, nonatomic) IBOutlet UILabel *transmitPowerLabel;
@property (weak, nonatomic) IBOutlet UISlider *transmitPowerSlider;
@property (weak, nonatomic) IBOutlet UIView *uuidField;
@property (weak, nonatomic) IBOutlet UITextField *majorField;
@property (weak, nonatomic) IBOutlet UITextField *minorField;

@end

@implementation BeaconBroadcastViewController
{
    @private
        CBPeripheralManager *_peripheralManager;
        NSUUID *_uuid;
        NSNumber *_major;
        NSNumber *_minor;
        NSNumber *_power;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
    return self;
}


- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    
}

- (void)viewWillAppear:(BOOL)animated
{
    // sync the broadcast switch
    self.broadcastSwitch.on = _peripheralManager.isAdvertising;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)broadcastSwitchTouched:(id)sender {
  
    if(_peripheralManager.state < CBPeripheralManagerStatePoweredOn)
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Bluetooth must be enabled" message:@"To configure your device as a beacon" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        
        return;
    }
    
    if([sender isOn])
    {
        // We must construct a CLBeaconRegion that represents the payload we want the device to beacon.
        NSDictionary *peripheralData = nil;
        if(_uuid && _major && _minor)
        {
            CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid major:[_major shortValue] minor:[_minor shortValue] identifier:@"us.dcrow.iBeaconManager"];
            peripheralData = [region peripheralDataWithMeasuredPower:_power];
        }
        else if(_uuid && _major)
        {
            CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid major:[_major shortValue]  identifier:@"us.dcrow.iBeaconManager"];
            peripheralData = [region peripheralDataWithMeasuredPower:_power];
        }
        else if(_uuid)
        {
            CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid identifier:@"us.dcrow.iBeaconManager"];
            peripheralData = [region peripheralDataWithMeasuredPower:_power];
        }
        
        // The region's peripheral data contains the CoreBluetooth-specific data we need to advertise.
        if(peripheralData)
        {
            [_peripheralManager startAdvertising:peripheralData];
        }
    }
    else
    {
        [_peripheralManager stopAdvertising];
    }

    
}

- (IBAction)transmitPowerSliderChanged:(id)sender {
}







//#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"Cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//    
//    // Configure the cell...
//    
//    return cell;
//}

@end
