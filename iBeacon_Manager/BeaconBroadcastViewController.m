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
@property (strong, nonatomic) IBOutlet UITextField *uuidField;
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
        UIImage *_whiteMarker;
        UIImage *_greenMarker;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
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
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    self.transmitPowerSlider.minimumValue = 0;
    self.transmitPowerSlider.maximumValue = 90;
    
    
    //Initialize reused tableview images
    _greenMarker = [[UIImage alloc] init];
    _greenMarker = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"722-location-ping@2x" ofType:@"png"]];
    
    _whiteMarker = [[UIImage alloc] init];
    _whiteMarker = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"722-location-pin@2x" ofType:@"png"]];
    
    
    //set default power and initial region properties TODO this in a less sloppy way
    self.transmitPowerLabel.text = [NSString stringWithFormat:@"-59 dB"];
    [self.transmitPowerSlider setValue:59 animated:NO];
    _power = @-59;
    
    _uuid = [[NSUUID alloc] initWithUUIDString:self.uuidField.text];
    _minor = [[NSNumber alloc] initWithDouble: [self.minorField.text doubleValue]];
    _major = [[NSNumber alloc] initWithDouble: [self.majorField.text doubleValue]];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)broadcastSwitchTouched:(id)sender {
  
    self.broadcastImage.image = _whiteMarker;
    
    if(_peripheralManager.state < CBPeripheralManagerStatePoweredOn)
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Bluetooth must be enabled" message:@"To configure your device as a beacon" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        
        return;
    }

    if([sender isOn])
    {
        self.broadcastImage.image = _greenMarker;
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
    self.transmitPowerLabel.text = [NSString stringWithFormat:@"-%1.0f dB", self.transmitPowerSlider.value];
    _power = [NSNumber numberWithFloat:self.transmitPowerSlider.value];
}


@end
