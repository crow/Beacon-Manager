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
    IBOutlet UIButton *emailButton;
    IBOutlet UITextField *urlTextField;
    IBOutlet UIButton *loadButton;
    IBOutlet UITableViewCell *availableBeaconsCell;
    NSURL *lastUrl;
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
    lastUrl = [[NSUserDefaults standardUserDefaults] URLForKey:@"lastUrl"];
    availableBeaconsCell.hidden = YES;
    loadButton.hidden = NO;
    availableBeaconsCell.alpha = 0;
    availableBeaconsCell.userInteractionEnabled = NO;

}

- (void)hideKeyboard
{
    //update field values on keyboard hide
    lastUrl = [NSURL URLWithString:urlTextField.text];
    [[NSUserDefaults standardUserDefaults]
     setURL:lastUrl forKey:@"lastUrl"];
    
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
    
    NSURL *url = [NSURL URLWithString:urlTextField.text];
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
//response callback that ensures this is a valid URL that exists, if plist is not present list will safely fail to popluate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([(NSHTTPURLResponse *)response statusCode] == 200) {
        // url exists
        [[[BeaconRegionManager shared] plistManager] loadHostedPlistFromUrl:[NSURL URLWithString:urlTextField.text]];
        availableBeaconsCell.hidden = NO;
        [UIView animateWithDuration:1 animations:^() {
            availableBeaconsCell.alpha = 1.0;
        }];
        availableBeaconsCell.userInteractionEnabled = YES;
        loadButton.hidden = NO;
        [[BeaconRegionManager shared] loadAvailableRegions];
        [[BeaconRegionManager shared] loadMonitoredRegions];
    }
}

- (void)showEmail{
    
    NSString *emailTitle = @"Sample iBeacon Manager Plist";
    NSString *messageBody = @"Host the attached plist list where ever you like, copy and paste the URL of the hosted file into the \"Load Remote iBeacon Plist\" text field and hit the cloud button.  The sample plist content can be altered for your use case, but not it's structure. The UUID, major and minor of the iBeacon regions outlined in the list must match the UUID, major and minor of the advertising iBeacons for the iBeacon Manager to function properly.  Enjoy.";
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
