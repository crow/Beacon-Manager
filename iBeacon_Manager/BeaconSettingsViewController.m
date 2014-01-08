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

@synthesize beaconRegion;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.beaconRegion.identifier;
    [self loadSwitchStates];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.monitorLabel.text = [NSString stringWithFormat:@"Monitor %@", self.beaconRegion.identifier];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(managerDidRangeBeacons)
     name:@"managerDidRangeBeacons"
     object:nil];
}

- (void)managerDidRangeBeacons
{
    [self updateView];
}

-(void)updateView
{
    NSString *proximity;
    NSString *rssi;
    
    rssi = (self.beacon.rssi == 0) ? @"---" : [NSString stringWithFormat:@"%ld", (long)self.beacon.rssi];
    proximity = (self.beacon.rssi == 0) ? @"---" : [NSString stringWithFormat:@"%1.3f ± %d m", self.beacon.accuracy, self.beacon.proximity];
    self.rssiLabel.text = rssi;
    self.proximityLabel.text = proximity;
}

- (IBAction)monitorSwitchTouched:(id)sender
{
    //if ON
    if ([sender isOn]) {
        [[BeaconRegionManager shared] startMonitoringBeaconInRegion:self.beaconRegion];
    }
    else{
        [[BeaconRegionManager shared] stopMonitoringBeaconInRegion:self.beaconRegion];
    }
    
    [self loadSwitchStates];
}

- (IBAction)notifyOnEntrySwitchTouched:(id)sender
{
    //if ON
    if ([sender isOn]) {
        self.beaconRegion.notifyOnEntry = YES;
    }
    else{
        self.beaconRegion.notifyOnEntry = NO;

    }
    
    [self loadSwitchStates];
}

- (IBAction)notifyOnExitSwitchTouched:(id)sender
{
    if ([sender isOn]) {
        self.beaconRegion.notifyOnExit= YES;
    }
    else{
        self.beaconRegion.notifyOnExit = NO;
        
    }
    
    [self loadSwitchStates];
}

- (IBAction)notifyEntryOnDisplaySwitchTouched:(id)sender
{
    if ([sender isOn]) {
        self.beaconRegion.notifyEntryStateOnDisplay = YES;
    }
    else{
        self.beaconRegion.notifyEntryStateOnDisplay = NO;
        
    }
    
    [self loadSwitchStates];
}


-(void)loadSwitchStates
{
    [self.monitorSwitch setOn:[[BeaconRegionManager shared] isMonitored:self.beaconRegion]];
    [self.noteEntrySwitch setOn:self.beaconRegion.notifyOnEntry];
    [self.noteExitSwitch setOn:self.beaconRegion.notifyOnExit];
    [self.noteEntryOnDisplaySwitch setOn:self.beaconRegion.notifyEntryStateOnDisplay];
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
        vc.beaconRegion = self.beaconRegion;
        vc.beacon = self.beacon;
        // Pass any objects to the view controller here, like...
        //[vc setMyObjectHere:object];
    }
}

@end
