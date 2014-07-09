//
//  BroadcastViewController.m
//  iBeacon_Manager
//
//  Created by David Crow on 1/20/14.
//  Copyright (c) 2014 David Crow. All rights reserved.
//

#import "BroadcastViewController.h"
#import "BeaconPulsingHaloLayer.h"
#import "RSCodeView.h"
#import "RSCodeGen.h"
#import "BeaconManagerValues.h"



@interface BroadcastViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *broadcastImage;
@property (weak, nonatomic) IBOutlet UISwitch *broadcastSwitch;
@property (weak, nonatomic) IBOutlet UILabel *transmitPowerLabel;
@property (weak, nonatomic) IBOutlet UISlider *transmitPowerSlider;

@property (strong, nonatomic) IBOutlet UIButton *generateUuidButton;

@property (nonatomic, strong) BeaconPulsingHaloLayer *halo;
@property (nonatomic, weak) IBOutlet UIImageView *beaconView;
@property (strong, nonatomic) IBOutlet UITableViewCell *broadcastCell;

//Barcode properties
@property (nonatomic, weak) IBOutlet RSCodeView *codeView;

@end

@implementation BroadcastViewController {
    @private
        CBPeripheralManager *_peripheralManager;
        NSUUID *_uuid;
        NSNumber *_major;
        NSNumber *_minor;
        NSNumber *_power;
        UIImage *_whiteMarker;
        UIImage *_greenMarker;
}
- (IBAction)generateUuidTapped:(id)sender {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    [self.uuidField setText:uuid];
    [self updateQRCode];
}

- (BOOL)validateUuidString: (NSString *)urlString {
    NSString *uuidRegEx =
    @"[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}";
    NSPredicate *uuidTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", uuidRegEx];
    return [uuidTest evaluateWithObject:urlString];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    //TODO update state here
}

-(void)updateQRCode {
    self.broadcastSwitch.on = _peripheralManager.isAdvertising;
    _uuid = [[NSUUID alloc] initWithUUIDString:[self.uuidField text]];
    _major = [[NSNumber alloc] initWithDouble:[[self.majorField text] doubleValue]];
    _minor = [[NSNumber alloc] initWithDouble:[[self.minorField text] doubleValue]];
    NSString *qrString = [NSString stringWithFormat:@"%@,%@,%@,%@.", [_uuid UUIDString], _major, _minor, @"Test_iBeacon"];
    self.codeView.code = [CodeGen genCodeWithContents:qrString machineReadableCodeObjectType:AVMetadataObjectTypeQRCode];
}

-(void)saveLastBroadcastSignature {
    if ([self.uuidField text] && [self.majorField text] && [self.uuidField text]) {
        [[NSUserDefaults standardUserDefaults] setObject:[self.uuidField text] forKey:kLastBroadcastUuidString];
        [[NSUserDefaults standardUserDefaults] setObject:[self.majorField text] forKey:kLastBroadcastMajorString];
        [[NSUserDefaults standardUserDefaults] setObject:[self.minorField text] forKey:kLastBroadcastMinorString];
    }
    
}

-(void)loadLastBroadcastSignature {
    if([[NSUserDefaults standardUserDefaults] valueForKey:kLastBroadcastUuidString] &&
       [[NSUserDefaults standardUserDefaults] valueForKey:kLastBroadcastMajorString] &&
       [[NSUserDefaults standardUserDefaults] valueForKey:kLastBroadcastMinorString]) {
        //if no saved switch state set to YES by default
    [self.uuidField setText:[[NSUserDefaults standardUserDefaults] valueForKey:kLastBroadcastUuidString]];
    [self.majorField setText:[[NSUserDefaults standardUserDefaults] valueForKey:kLastBroadcastMajorString]];
    [self.minorField setText:[[NSUserDefaults standardUserDefaults] valueForKey:kLastBroadcastMinorString]];
        
        _uuid = [[NSUUID alloc] initWithUUIDString:[self.uuidField text]];
        _major = [[NSNumber alloc] initWithDouble:[[self.majorField text] doubleValue]];
        _minor = [[NSNumber alloc] initWithDouble:[[self.minorField text] doubleValue]];
   }
    else {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        [self.uuidField setText:uuid];
        [self.majorField setText:0];
        [self.minorField setText:0];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [self loadLastBroadcastSignature];
}
-(void)viewWillDisappear:(BOOL)animated {
    [self saveLastBroadcastSignature];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateQRCode];
    [self loadLastBroadcastSignature];
    
        //halo view
    self.halo = [BeaconPulsingHaloLayer layer];
    self.halo.radius = 0;
    self.halo.position = self.beaconView.center;
    [self.view.layer insertSublayer:self.halo below:self.beaconView.layer];
    //set up halo color
    UIColor *color = [UIColor colorWithRed:0
                                     green:1.0
                                      blue:0.48
                                     alpha:1.0];
    
    self.halo.backgroundColor = color.CGColor;
    
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    self.transmitPowerSlider.minimumValue = 1;
    self.transmitPowerSlider.maximumValue = 90;
    
    //for naturally exiting the keyboard
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.tableView addGestureRecognizer:gestureRecognizer];
    gestureRecognizer.cancelsTouchesInView = NO;
    
    self.view.userInteractionEnabled = TRUE;
    
    //Initialize reused tableview images
    _greenMarker = [[UIImage alloc] init];
    _greenMarker = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"722-location-ping@2x" ofType:@"png"]];
    
    _whiteMarker = [[UIImage alloc] init];
    _whiteMarker = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"722-location-pin@2x" ofType:@"png"]];
    
    //set default power and initial region properties TODO this in a less sloppy way
    self.transmitPowerLabel.text = [NSString stringWithFormat:@"-59 dB"];
    [self.transmitPowerSlider setValue:59 animated:NO];
    _power = @-59;
}

- (void)hideKeyboard {
    //save last set
    [self saveLastBroadcastSignature];
    
    //update QR code
    [self updateQRCode];
    
    //update field values on keyboard hide
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)broadcastSwitchTouched:(id)sender {
  
    self.broadcastImage.image = _whiteMarker;
    self.beaconView.image = _whiteMarker;
    self.halo.radius = 0;
    

    if (![self validateUuidString:self.uuidField.text]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"UUID you provided is not not valid, please double check the UUID and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        [sender setOn:NO animated:YES];
        return;
    }
    
    if(_peripheralManager.state < CBPeripheralManagerStatePoweredOn) {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Bluetooth must be enabled" message:@"To configure your device as a beacon" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        //reset switch position
        [sender setOn:NO animated:YES];
        
        return;
    }

    if([sender isOn]) {
       
        self.broadcastImage.image = _greenMarker;
        self.beaconView.image = _greenMarker;
        self.halo.radius = self.transmitPowerSlider.value * kMaxRadius;
        self.transmitPowerSlider.enabled = NO;
        self.transmitPowerSlider.userInteractionEnabled = NO;
        [self.tableView reloadData];
        // We must construct a CLBeaconRegion that represents the payload we want the device to beacon.
        NSDictionary *peripheralData = nil;
        if(_uuid && _major && _minor) {
            CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid major:[_major shortValue] minor:[_minor shortValue] identifier:[[UIDevice currentDevice] name]];
            peripheralData = [region peripheralDataWithMeasuredPower:_power];
        }
        else if(_uuid && _major) {
            CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid major:[_major shortValue]  identifier:[[UIDevice currentDevice] name]];
            peripheralData = [region peripheralDataWithMeasuredPower:_power];
        }
        else if(_uuid) {
            CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:_uuid identifier:[[UIDevice currentDevice] name]];
            peripheralData = [region peripheralDataWithMeasuredPower:_power];
        }
        
        // The region's peripheral data contains the CoreBluetooth-specific data we need to advertise.
        if(peripheralData) {
            [_peripheralManager startAdvertising:peripheralData];
        }
    }
    else {
        self.transmitPowerSlider.enabled = YES;
        self.transmitPowerSlider.userInteractionEnabled = YES;
        [_peripheralManager stopAdvertising];
    }
}

- (IBAction)transmitPowerSliderChanged:(id)sender {
    
    if ([self.broadcastSwitch isOn]) {
    self.halo.radius = self.transmitPowerSlider.value * kMaxRadius;
    //self.radiusLabel.text = [@(self.transmitPowerSlider) stringValue];
    }

    self.transmitPowerLabel.text = [NSString stringWithFormat:@"-%1.0f dB", self.transmitPowerSlider.value];

    _power = [NSNumber numberWithFloat:self.transmitPowerSlider.value];
}


@end
