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

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self){
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.beaconRegion.identifier;
    [self loadSwitchStates];

    self.monitorLabel.text = [NSString stringWithFormat:@"Monitor %@", self.beaconRegion.identifier];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(managerDidRangeBeacons)
     name:@"managerDidRangeBeacons"
     object:nil];
}

- (void)managerDidRangeBeacons {
    [self updateView];
}

-(void)updateView {
    NSString *proximity;
    NSString *rssi;
    
    //don't let the beacon get stale - for some reason it was TODO look into why this is necessary
    self.beacon = [[BeaconRegionManager shared] beaconWithId:self.beaconRegion.identifier];
    
    rssi = (self.beacon.rssi == 0) ? @"---" : [NSString stringWithFormat:@"%ld", (long)self.beacon.rssi];
    proximity = (self.beacon.rssi == 0) ? @"---" : [NSString stringWithFormat:@"%1.3f ± %d m", self.beacon.accuracy, self.beacon.proximity];
    self.rssiLabel.text = rssi;
    self.proximityLabel.text = proximity;
}

- (IBAction)monitorSwitchTouched:(id)sender {
    //if ON
    if ([sender isOn]) {
        [[BeaconRegionManager shared] startMonitoringBeaconInRegion:self.beaconRegion];
    }
    else {
        [[BeaconRegionManager shared] stopMonitoringBeaconInRegion:self.beaconRegion];
    }
    
    [self loadSwitchStates];
}

-(void)loadSwitchStates {
    [self.monitorSwitch setOn:[[BeaconRegionManager shared] isMonitored:self.beaconRegion]];
    [self.noteEntrySwitch setOn:self.beaconRegion.notifyOnEntry];
    [self.noteExitSwitch setOn:self.beaconRegion.notifyOnExit];
    [self.noteEntryOnDisplaySwitch setOn:self.beaconRegion.notifyEntryStateOnDisplay];
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (cell.tag == 1) {
        if (self.beaconRegion.notifyOnEntry == YES) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    if (cell.tag == 2) {
        if (self.beaconRegion.notifyOnExit == YES) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    if (cell.tag == 3) {
        if (self.beaconRegion.notifyEntryStateOnDisplay) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];

    if (cell.tag == 1) {
        //Tag On Entry
        if (cell.accessoryType != UITableViewCellAccessoryCheckmark) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.beaconRegion.notifyOnEntry = YES;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            self.beaconRegion.notifyOnEntry = NO;
        }
    }
    if (cell.tag == 2) {
        //Tag On Exit
        if (cell.accessoryType != UITableViewCellAccessoryCheckmark) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.beaconRegion.notifyOnExit = YES;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            self.beaconRegion.notifyOnExit = NO;
        }
    }
    if (cell.tag == 3) {
        //Tag On Display
        if (cell.accessoryType != UITableViewCellAccessoryCheckmark) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.beaconRegion.notifyEntryStateOnDisplay = YES;

        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            self.beaconRegion.notifyEntryStateOnDisplay = NO;

        }
    }
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"beaconStats"]) {
        // Get reference to the destination view controller
        BeaconStatsViewController *vc = [segue destinationViewController];
        vc.beaconRegion = self.beaconRegion;
        vc.beacon = self.beacon;
    }
    if ([[segue identifier] isEqualToString:@"exitTags"]) {
        // Get reference to the destination view controller
        BeaconStatsViewController *vc = [segue destinationViewController];
        vc.beaconRegion = self.beaconRegion;
        vc.beacon = self.beacon;
    }
    if ([[segue identifier] isEqualToString:@"entryTags"]) {
        // Get reference to the destination view controller
        BeaconStatsViewController *vc = [segue destinationViewController];
        vc.beaconRegion = self.beaconRegion;
        vc.beacon = self.beacon;
    }
}

@end
