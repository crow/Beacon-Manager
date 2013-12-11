//
//  BeaconSettingsViewController.m
//  UABeacons
//
//  Created by David Crow on 11/3/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "BeaconSettingsViewController.h"

@interface BeaconSettingsViewController ()

@end

@implementation BeaconSettingsViewController

@synthesize managedBeaconRegion;

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
    [super viewDidLoad];
    self.title = self.managedBeaconRegion.identifier;
    [self loadSwitchStates];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.monitorLabel.text = [NSString stringWithFormat:@"Monitor %@", self.managedBeaconRegion.identifier];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(managerDidRangeBeacons)
     name:@"managerDidRangeBeacons"
     object:nil];
}

- (void)managerDidRangeBeacons
{
    NSString *proximity;
    NSString *rssi;
    
    rssi = (managedBeaconRegion.beacon.rssi == 0) ? @"---" : [NSString stringWithFormat:@"%ld", (long)managedBeaconRegion.beacon.rssi];
    proximity = (managedBeaconRegion.beacon.rssi == 0) ? @"---" : [NSString stringWithFormat:@"%1.3f ± %d m", managedBeaconRegion.beacon.accuracy, managedBeaconRegion.beacon.proximity];
    self.rssiLabel.text = rssi;
    self.proximityLabel.text = proximity;
}


- (IBAction)monitorSwitchTouched:(id)sender
{
    //if ON
    if ([sender isOn]) {
        [[BeaconRegionManager shared] startMonitoringBeaconInRegion:self.managedBeaconRegion];
    }
    else{
        [[BeaconRegionManager shared] stopMonitoringBeaconInRegion:self.managedBeaconRegion];
    }
    
    [self loadSwitchStates];
}

- (IBAction)notifyOnEntrySwitchTouched:(id)sender
{
    //if ON
    if ([sender isOn]) {
        self.managedBeaconRegion.notifyOnEntry = YES;
    }
    else{
        self.managedBeaconRegion.notifyOnEntry = NO;

    }
    
    [self loadSwitchStates];
}

- (IBAction)notifyOnExitSwitchTouched:(id)sender
{
    if ([sender isOn]) {
        self.managedBeaconRegion.notifyOnExit= YES;
    }
    else{
        self.managedBeaconRegion.notifyOnExit = NO;
        
    }
    
    [self loadSwitchStates];
}

- (IBAction)notifyEntryOnDisplaySwitchTouched:(id)sender
{
    if ([sender isOn]) {
        self.managedBeaconRegion.notifyEntryStateOnDisplay = YES;
    }
    else{
        self.managedBeaconRegion.notifyEntryStateOnDisplay = NO;
        
    }
    
    [self loadSwitchStates];
}


-(void)loadSwitchStates
{
   //this is ugly, can probably be handled with ternary operators
    if ([[BeaconRegionManager shared] isMonitored:self.managedBeaconRegion])
    {
        [self.monitorSwitch setOn:YES];
    }
    else{
        [self.monitorSwitch setOn:NO];
    }

    if (self.managedBeaconRegion.notifyOnEntry == YES)
    {
        [self.noteEntrySwitch setOn:YES];
    }
    else{
        [self.noteEntrySwitch setOn:NO];
    }

    
    if (self.managedBeaconRegion.notifyOnExit == YES)
    {
        [self.noteExitSwitch setOn:YES];
    }
    else{
        [self.noteExitSwitch setOn:NO];
    }
    
    
    if (self.managedBeaconRegion.notifyEntryStateOnDisplay == YES)
    {
        [self.noteEntryOnDisplaySwitch setOn:YES];
    }
    else{
        [self.noteEntryOnDisplaySwitch setOn:NO];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"beaconStats"])
    {
        // Get reference to the destination view controller
        BeaconStatsViewController *vc = [segue destinationViewController];
        vc.managedBeaconRegion = self.managedBeaconRegion;
        vc.beacon = self.managedBeaconRegion.beacon;
        // Pass any objects to the view controller here, like...
        //[vc setMyObjectHere:object];
    }
}

@end
