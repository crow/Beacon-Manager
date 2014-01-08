//
//  BeaconListViewController.m
//  iBeacon_Manager
//
//  Created by David Crow on 11/18/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "BeaconListViewController.h"
#import "PlistManager.h"
#import "BeaconRegionManager.h"
#import <MessageUI/MessageUI.h>


@interface BeaconListViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation BeaconListViewController
{
    IBOutlet UIButton *_emailButton;
    IBOutlet UITextField *_urlTextField;
    IBOutlet UIButton *_loadButton;
    IBOutlet UITableViewCell *_availableBeaconsCell;
    NSURL *_lastUrl;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)emailButtonTouched:(id)sender {
    [self showEmail];
}

- (void)viewDidLoad
{
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.tableView addGestureRecognizer:gestureRecognizer];
    gestureRecognizer.cancelsTouchesInView = NO;
    self.view.userInteractionEnabled = TRUE;
    [super viewDidLoad];
    //[PlistManager shared];
    _lastUrl = [[NSUserDefaults standardUserDefaults] URLForKey:@"lastUrl"];
    //[[BeaconRegionManager shared] loadAvailableRegions];
    [self beaconLoadCheck];
}

- (void)hideKeyboard
{
    //update field values on keyboard hide
    _lastUrl = [NSURL URLWithString:_urlTextField.text];
    [[NSUserDefaults standardUserDefaults]
     setURL:_lastUrl forKey:@"lastUrl"];
    
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (IBAction)reloadBeaconList:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please ensure your URL is correct" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSURL *url = [NSURL URLWithString:_urlTextField.text];
    // the user clicked OK
    if (buttonIndex == 0)
    {
        if (url != nil)
        {
           //check if
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            [request setHTTPMethod:@"HEAD"];
            [NSURLConnection connectionWithRequest:request delegate:self];
        }
    }
}

//helper for determining if a beacon list has been loaded
-(void)beaconLoadCheck
{
    if ([[BeaconRegionManager shared] availableBeaconRegionsList])
    {
        _availableBeaconsCell.hidden = NO;
        [UIView animateWithDuration:1 animations:^() {
            _availableBeaconsCell.alpha = 1.0;
        }];
        _availableBeaconsCell.userInteractionEnabled = YES;
    }
    else
    {
        _availableBeaconsCell.hidden = YES;
        _availableBeaconsCell.alpha = 0;
        _availableBeaconsCell.userInteractionEnabled = NO;
    }
}

//response callback that ensures this is a valid URL that exists, if plist is not present list will safely fail to popluate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([(NSHTTPURLResponse *)response statusCode] == 200) {
        
        //clear any beaconRegions stored in the locationManager
        [[BeaconRegionManager shared] stopMonitoringAllBeaconRegions];
        //initialize ibeacon manager, load iBeacon plist, load available regions, start monitoring available regions
        // url exists
        [[[BeaconRegionManager shared] plistManager] loadHostedPlistWithUrl:[NSURL URLWithString:_urlTextField.text]];
        [[BeaconRegionManager shared] startManager];

        _availableBeaconsCell.hidden = NO;
        [UIView animateWithDuration:1 animations:^() {
            _availableBeaconsCell.alpha = 1.0;
        }];
        _availableBeaconsCell.userInteractionEnabled = YES;
    }
}

- (void)showEmail{
    
    NSString *emailTitle = @"Sample iBeacon Manager Plist";
    NSString *messageBody = @"iBeacon Manager\n\nGetting Started:\nHost the attached plist, copy and paste the URL of the hosted file into the \"Load Remote iBeacon Plist\" text field and hit the download button (the cloud with a downward facing arrow).  A simple way to host a file is to store it on dropbox or similar cloud file storage service and use the file's shared download link.\n\nImportant:\nThe sample plist content can be altered for your use case, but it's structure cannot. The UUID, major and minor of the iBeacon regions outlined in the plist must match the UUID, major and minor of the advertising iBeacons for the iBeacon Manager to function properly.\n\nEnjoy";
    NSArray *toRecipents = [NSArray arrayWithObject:@"Your email here"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    
    NSString* plistBeaconRegionsPath = [[NSBundle mainBundle] pathForResource:@"BeaconRegions" ofType:@"plist"];
    NSData *fileData = [NSData dataWithContentsOfFile:plistBeaconRegionsPath];
    
    // MIME type is XML (plist)
    NSString *mimeType = @"application/xml";

    
    // Add attachment
    [mc addAttachmentData:fileData mimeType:mimeType fileName:@"BeaconRegions"];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}


@end
