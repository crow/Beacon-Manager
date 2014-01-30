//
//  BeaconListViewController.m
//  iBeacon_Manager
//
//  Created by David Crow on 11/18/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "BeaconListViewController.h"
#import "BeaconPlistManager.h"
#import "BeaconRegionManager.h"
#import <MessageUI/MessageUI.h>
#import "BeaconManagerValues.h"



@interface BeaconListViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation BeaconListViewController
{
    IBOutlet UIButton *_emailButton;
    IBOutlet UITextField *_urlTextField;
    IBOutlet UIButton *_loadButton;
    IBOutlet UITableViewCell *_availableBeaconsCell;
    NSURL *_lastUrl;
    BOOL loading;
    IBOutlet UIProgressView *remoteLoadProgress;
    
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

- (IBAction)loadSampleButtonPressed:(id)sender {
    

    if (!loading)
    {
    //clear any beaconRegions stored in the locationManager
    [[BeaconRegionManager shared] stopMonitoringAllBeaconRegions];
    [[[BeaconRegionManager shared] plistManager] loadLocalPlist];
    
    _availableBeaconsCell.hidden = NO;
    
    //fade in and out to show loading
    [UIView animateWithDuration:0.5 animations:^() {
        _availableBeaconsCell.alpha = 0.5;
    }];
    [UIView animateWithDuration:0.5 animations:^() {
        _availableBeaconsCell.alpha = 1.0;
    }];
    _availableBeaconsCell.userInteractionEnabled = YES;
    }
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
    loading = NO;
    remoteLoadProgress.hidden = YES;
    
    
    //set initial available state
    _availableBeaconsCell.hidden = YES;
    _availableBeaconsCell.alpha = 0;
    _availableBeaconsCell.userInteractionEnabled = NO;
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
    
    loading = YES;
    //update UI to reflect loading new list
    [self beaconLoadCheck];
    NSURL *url = [NSURL URLWithString:_urlTextField.text];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    
    if ([self validateUrl:[url absoluteString]])
    {
        remoteLoadProgress.hidden = NO;
        remoteLoadProgress.progress = 0.0;
        [self performSelectorOnMainThread:@selector(setProgress) withObject:nil waitUntilDone:NO];
        
        //Make the request TODO this is a lame way of doing this, to improve soon
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"HEAD"];
        [NSURLConnection connectionWithRequest:request delegate:self];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"URL provided is not not valid, please double check the URL and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
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
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"URL provided is not responding, please double check the URL and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (BOOL) validateUrl: (NSString *)urlString {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:urlString];
}

- (void)setProgress
{
    float actual = [remoteLoadProgress progress];
    if (actual < 1) {
        
        //should add receiveddata/expected data
        loading = YES;
        remoteLoadProgress.progress = actual + 0.01;
        [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(setProgress) userInfo:nil repeats:NO];
    }
    else
    {
        loading = NO;
        remoteLoadProgress.hidden = YES;
        //load available regions for beacon load check
        [[BeaconRegionManager shared] loadAvailableRegions];
        [self beaconLoadCheck];
    }
}

//helper for determining if a beacon list has been loaded
-(void)beaconLoadCheck
{
    if ([[BeaconRegionManager shared] availableBeaconRegionsList] && !loading)
    {
        _availableBeaconsCell.userInteractionEnabled = YES;
        _availableBeaconsCell.hidden = NO;
        [UIView animateWithDuration:0.5 animations:^() {
            _availableBeaconsCell.alpha = 1.0;
        }];
    }
    else
    {
        _availableBeaconsCell.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.5 animations:^() {
            _availableBeaconsCell.alpha = 0.0;
        }];
        _availableBeaconsCell.hidden = YES;
    }
}

- (void)showEmail{
    
    NSString *emailTitle = @"Sample iBeacon Manager Plist";
    NSString *messageBody = kTutorialString;
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
