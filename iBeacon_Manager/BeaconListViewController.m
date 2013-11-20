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

@implementation BeaconListViewController {

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
    
    lastUrl = [[NSUserDefaults standardUserDefaults]
                        URLForKey:@"lastUrl"];
    //if last url is nil then change the text field to "Enter URL here" 
    lastUrl ? [self.beaconListURL setText:[lastUrl absoluteString]] : [self.beaconListURL setText:@"Enter URL here"];
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)hideKeyboard{
    //update field values on keyboard hide
    lastUrl = [NSURL URLWithString:self.beaconListURL.text];
    [[NSUserDefaults standardUserDefaults]
     setURL:lastUrl forKey:@"lastUrl"];
    
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)reloadBeaconList:(id)sender {

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This generates a synchronous blocking call - if it takes too long system watchdog might kill the process.  Please ensure your URL is correct" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
    [alert show];
 
    
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;{
    // the user clicked OK
    if (buttonIndex == 0)
    {
        [[PlistManager shared] loadHostedPlistFromUrl:[NSURL URLWithString:self.beaconListURL.text]];
        [[BeaconRegionManager shared] updateAvailableRegions];
        [[BeaconRegionManager shared] updateMonitoredRegions];
    }
}


@end
