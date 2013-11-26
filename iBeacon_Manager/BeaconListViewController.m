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

@interface BeaconListViewController ()

@end

@implementation BeaconListViewController
{
    __strong IBOutlet UIActivityIndicatorView *urlLoadingIndicator;
    __strong IBOutlet UITextField *urlTextField;
    __strong IBOutlet UIButton *loadButton;
    __strong IBOutlet UITableViewCell *availableBeaconsCell;
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
    urlLoadingIndicator.hidden = YES;
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


@end
