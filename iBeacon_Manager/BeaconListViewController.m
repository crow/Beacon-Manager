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
    self.viewAvailableIbeaconsCell.userInteractionEnabled = NO;

}

- (void)hideKeyboard
{
    //update field values on keyboard hide
    lastUrl = [NSURL URLWithString:self.beaconListURL.text];
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

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This generates a synchronous blocking call - if it takes too long system watchdog might kill the process.  Please ensure your URL is correct" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // the user clicked OK
    if (buttonIndex == 0)
    {
        [[PlistManager shared] loadHostedPlistFromUrl:[NSURL URLWithString:self.beaconListURL.text]];
        [[BeaconRegionManager shared] updateAvailableRegions];
        [[BeaconRegionManager shared] updateMonitoredRegions];
        if ([NSURL URLWithString:self.beaconListURL.text] != nil) {
            self.viewAvailableIbeaconsCell.userInteractionEnabled = YES;
        }
        [[BeaconRegionManager shared] updateAvailableRegions];
        [[BeaconRegionManager shared] updateMonitoredRegions];
    }
}


@end
