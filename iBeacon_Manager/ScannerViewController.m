
//  ViewController.m
//  Scanner App
//
//  Created by iRare Media on 12/4/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "ScannerViewController.h"
#import "BeaconRegionManager.h"
#import "BeaconListManager.h"

@interface ScannerViewController ()
@end

@implementation ScannerViewController
@synthesize scannerView, statusText;

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Set verbose logging to YES so we can see exactly what's going on
    [scannerView setVerboseLogging:YES];
    
    // Set animations to YES for some nice effects
    [scannerView setAnimateScanner:YES];
    
    // Set code outline to YES for a box around the scanned code
    [scannerView setDisplayCodeOutline:YES];
    
    // Start the capture session when the view loads - this will also start a scan session
    [scannerView startCaptureSession];
    
    // Set the title of the toggle button
    self.sessionToggleButton.title = @"Stop";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startNewScannerSession:(id)sender {
    if ([scannerView isScanSessionInProgress]) {
        [scannerView stopScanSession];
        self.sessionToggleButton.title = @"Start";
    } else {
        [scannerView startScanSession];
        self.sessionToggleButton.title = @"Stop";
    }
}


//TODO, halt scanning while alert view is present to prevent multiple scans
- (void)didScanCode:(NSString *)scannedCode onCodeType:(NSString *)codeType {
    
    //Split the comma separated QR code string into the UUIDstring majorstring and minorstring
    NSArray *beaconRegionProperties = [scannedCode componentsSeparatedByString: @","];
    
    //add checking to make sure these objects are at their proper indexes
    NSString *uuidString = [beaconRegionProperties objectAtIndex:0];
    NSString *majorString = [beaconRegionProperties objectAtIndex:1];
    NSString *minorString = [beaconRegionProperties objectAtIndex:2];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Scanned Beacon %@ code", [scannerView humanReadableCodeTypeForCode:codeType]] message:[NSString stringWithFormat:@"UUID:%@\n\nMajor:%@\n\nMinor:%@", uuidString, majorString, minorString]  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Scan Again", nil];
   
    //start monitoring the QR coded beacon region
    [[[BeaconRegionManager shared] listManager] loadSingleBeaconRegion:[self beaconRegionFromScannedCode:scannedCode]];

    
    [alert show];
}

//TODO a better check on the QR code to make sure this doesn't fail elsewhere
-(CLBeaconRegion *)beaconRegionFromScannedCode:(NSString *)code
{
    
    //Split the comma separated QR code string into the UUIDstring majorstring and minorstring
NSArray *beaconRegionProperties = [code componentsSeparatedByString: @","];
    
    //add checking to make sure these objects are at their proper indexes
    NSString *uuidString = [beaconRegionProperties objectAtIndex:0];
    NSString *majorString = [beaconRegionProperties objectAtIndex:1];
    NSString *minorString = [beaconRegionProperties objectAtIndex:2];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];

    //Todo add capability to add airship identifier for fun
    return [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:[majorString doubleValue] minor:[minorString doubleValue] identifier:@"Airship"];

}

- (void)errorGeneratingCaptureSession:(NSError *)error {
    [scannerView stopCaptureSession];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unsupported Device" message:@"This device does not have a camera. Run this app on an iOS device that has a camera." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alert show];
    
    statusText.text = @"Unsupported Device";
    self.sessionToggleButton.title = @"Error";
}

- (void)errorAcquiringDeviceHardwareLock:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Focus Unavailable" message:@"Tap to focus is currently unavailable. Try again in a little while." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (BOOL)shouldEndSessionAfterFirstSuccessfulScan {
    // Return YES to only scan one barcode, and then finish - return NO to continually scan.
    // If you plan to test the return NO functionality, it is recommended that you remove the alert view from the "didScanCode:" delegate method implementation
    // The Display Code Outline only works if this method returns NO
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Scan Again"]) {
        [scannerView startScanSession];
        self.sessionToggleButton.title = @"Stop";
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"]) {
        
        //[self performSegueWithIdentifier:@"Broadcast" sender:self];
        [self.navigationController popViewControllerAnimated:YES];
        self.sessionToggleButton.title = @"Start";
    }
}

//this can probably be removed
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"AvailableBeaconList"])
    {
        
       // UABeaconSampleAirshipViewController *dvController = [self.storyboard instantiateViewControllerWithIdentifier:@"UABeaconSampleAirshipViewController"];
    
       // dvController = segue.destinationViewController;
    }
    if([[segue identifier] isEqualToString:@"Broadcast"])
    {
        
        // UABeaconSampleAirshipViewController *dvController = [self.storyboard instantiateViewControllerWithIdentifier:@"UABeaconSampleAirshipViewController"];
        
        // dvController = segue.destinationViewController;
    }
}

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}
@end
