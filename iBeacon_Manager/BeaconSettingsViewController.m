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
    if (self) {
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

-(void)viewWillAppear
{
   // [self.navigationController setNavigationBarHidden:NO];
}

- (void)managerDidRangeBeacons
{
    
}


- (IBAction)monitorSwitchTouched:(id)sender {
    //if ON
    if ([sender isOn]) {
        [[BeaconRegionManager shared] startMonitoringBeaconInRegion:self.beaconRegion];
    }
    else{
        [[BeaconRegionManager shared] stopMonitoringBeaconInRegion:self.beaconRegion];
    }
    
    [self loadSwitchStates];
}

- (IBAction)notifyOnEntrySwitchTouched:(id)sender {
    //if ON
    if ([sender isOn]) {
        self.beaconRegion.notifyOnEntry = YES;
    }
    else{
        self.beaconRegion.notifyOnEntry = NO;

    }
    
    [self loadSwitchStates];
}

- (IBAction)notifyOnExitSwitchTouched:(id)sender {
    if ([sender isOn]) {
        self.beaconRegion.notifyOnExit= YES;
    }
    else{
        self.beaconRegion.notifyOnExit = NO;
        
    }
    
    [self loadSwitchStates];
}

- (IBAction)notifyEntryOnDisplaySwitchTouched:(id)sender {
    if ([sender isOn]) {
        self.beaconRegion.notifyEntryStateOnDisplay = YES;
    }
    else{
        self.beaconRegion.notifyEntryStateOnDisplay = NO;
        
    }
    
    [self loadSwitchStates];
}


-(void)loadSwitchStates{
    
    if ([[BeaconRegionManager shared] isMonitored:self.beaconRegion]) {
        [self.monitorSwitch setOn:YES];
    }
    else{
        [self.monitorSwitch setOn:NO];
    }

    if (self.beaconRegion.notifyOnEntry == YES) {
        [self.noteEntrySwitch setOn:YES];
    }
    else{
        [self.noteEntrySwitch setOn:NO];
    }

    
    if (self.beaconRegion.notifyOnExit == YES) {
        [self.noteExitSwitch setOn:YES];
    }
    else{
        [self.noteExitSwitch setOn:NO];
    }
    
    
    if (self.beaconRegion.notifyEntryStateOnDisplay == YES) {
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
        vc.beaconRegion = self.beaconRegion;
        vc.beacon = self.beaconRegion.beacon;
        // Pass any objects to the view controller here, like...
        //[vc setMyObjectHere:object];
    }
}

@end
