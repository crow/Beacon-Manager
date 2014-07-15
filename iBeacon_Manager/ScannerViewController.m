
//  ViewController.m
//  Scanner App
//
//  Created by iRare Media on 12/4/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "ScannerViewController.h"
#import "BeaconRegionManager.h"
#import "BeaconListManager.h"
#import "BroadcastViewController.h"
#import "BeaconListViewController.h"
@interface ScannerViewController ()
@property (nonatomic) NSString *lastScannedCode;
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
    //self.sessionToggleButton.title = @"Stop";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Just a stopgap since this is implemented in the UI, will move this at some point
- (UIViewController *)backViewController {
    NSArray * stack = self.navigationController.viewControllers;
    
    for (int i=stack.count-1; i > 0; --i)
        if (stack[i] == self)
            return stack[i-1];
    
    return nil;
}

//TODO, halt scanning while alert view is present to prevent multiple scans
- (void)didScanCode:(NSString *)scannedCode onCodeType:(NSString *)codeType {
    
    NSArray *beaconRegions = [self beaconRegionsFromScannedCode:scannedCode];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Beacon %@ Scan resulted in %d Beacon Regions", [scannerView humanReadableCodeTypeForCode:codeType], [beaconRegions count]] message:nil  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Scan Again", nil];
    self.lastScannedCode = scannedCode;
 
    [alert show];
}

//TODO a better check on the QR code to make sure this doesn't fail elsewhere
-(NSArray *)beaconRegionsFromScannedCode:(NSString *)scannedCode {
    
    //Split the newline separated beacon regions into an array of comma separated beacon region properties strings
    
    
    NSMutableArray *beaconRegions = [[NSMutableArray alloc] init];
    
    for (NSString *beaconRegionPropertiesString in [scannedCode componentsSeparatedByString: @"."]) {
        NSArray *beaconRegionProperties = [beaconRegionPropertiesString componentsSeparatedByString: @","];
        
        //add checking to make sure these objects are at their proper indexes
        if ([beaconRegionProperties count] == 4) {
            NSString *uuidString = [beaconRegionProperties objectAtIndex:0];
            NSString *majorString = [beaconRegionProperties objectAtIndex:1];
            NSString *minorString = [beaconRegionProperties objectAtIndex:2];
            NSString *identifierString = [beaconRegionProperties objectAtIndex:3];
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
            
            CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:[majorString doubleValue] minor:[minorString doubleValue] identifier:identifierString];
            
            [beaconRegions addObject:beaconRegion];
        }
        else {
            NSLog(@"QR Code is improperly formatted");
        }
    }

    return [NSArray arrayWithArray:beaconRegions];
}

- (void)errorGeneratingCaptureSession:(NSError *)error {
    [scannerView stopCaptureSession];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unsupported Device" message:@"This device does not have a camera. Run this app on an iOS device that has a camera." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alert show];
    
    statusText.text = @"Unsupported Device";
    //self.sessionToggleButton.title = @"Error";
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
        //self.sessionToggleButton.title = @"Stop";
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"]) {
        
        //[self performSegueWithIdentifier:@"Broadcast" sender:self];
        
        
        if ( [[self backViewController] isMemberOfClass:[BroadcastViewController class]]) {
            NSLog(@"print");
            //TODO change the fields of the view controller
        }
        if ( [[self backViewController] isMemberOfClass:[BeaconListViewController class]]) {
            //start monitoring the QR coded beacon region
            [[[BeaconRegionManager shared] listManager] loadBeaconRegionsArray:[self beaconRegionsFromScannedCode:self.lastScannedCode]];
        }
        
        [self.navigationController popViewControllerAnimated:YES];
        //self.sessionToggleButton.title = @"Start";
    }
}

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}
@end
