//
//  BeaconListViewController.m
//  iBeacon_Manager
//
//  Created by David Crow on 11/18/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "BeaconListViewController.h"
#import "BeaconRegionManager.h"
#import <MessageUI/MessageUI.h>
#import "BeaconManagerValues.h"
#import "BeaconRegionManagerDelegate.h"
#import "UALocationService.h"

@interface BeaconListViewController () <BeaconRegionManagerDelegate>


@end

@implementation BeaconListViewController{

    IBOutlet UITableViewCell *_availableBeaconsCell;
    BOOL loading;

}

- (id)initWithStyle:(UITableViewStyle)style{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad{

    self.view.userInteractionEnabled = YES;
    [super viewDidLoad];
    loading = NO;

    
    //set beacon region delegate to self
    [[BeaconRegionManager shared] setBeaconRegionManagerDelegate:self];

    
    //if there are regions being currently monitored, load those by default
    if ([[[[BeaconRegionManager shared] locationManager] monitoredRegions] count] > 0) {
        [[[BeaconRegionManager shared] listManager] loadLastMonitoredList];
    }
    else {
        [[[BeaconRegionManager shared] listManager] loadLocalPlist];
    }
    
    [[BeaconRegionManager shared] startManager];
    
    //automatically reveal available beacon cell
    [self enableAvailableBeaconCell];
}


-(void)viewWillAppear:(BOOL)animated{

}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma UI helpers
-(void)enableAvailableBeaconCell{
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

-(void)disableAvailableBeaconCell{
    _availableBeaconsCell.hidden = NO;

    [UIView animateWithDuration:0.5 animations:^() {
        _availableBeaconsCell.alpha = 0.5;
    }];
    _availableBeaconsCell.userInteractionEnabled =  NO;
}

//helper for determining if a beacon list has been loaded
-(void)beaconLoadCheck{
    if ([[[BeaconRegionManager shared] listManager] availableBeaconRegionsList] && !loading){
        [self enableAvailableBeaconCell];
    }
    else{
        [self disableAvailableBeaconCell];
    }
}

//manually deselect the row to keep it from being stuck
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

  UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    
    //Load sample list
    if (cell.tag == 3) {
        if (!loading){
            //clear any beaconRegions stored in the locationManager
            [[BeaconRegionManager shared] stopMonitoringAllBeaconRegions];
            [[[BeaconRegionManager shared] listManager] loadLocalPlist];
            
            //automatically reveal available beacon cell
            [self enableAvailableBeaconCell];
            
        }
    }
}

#pragma BeaconRegionManagerDelegate
//I thought I may need to know where the list was coming from, not sure if I do no, will simplify this lots

-(void)localListFinishedLoadingWithList:(NSArray *)localBeaconList{
    //done loading
    loading = NO;
    [self beaconLoadCheck];
    [self enableAvailableBeaconCell];
}

-(void)qRBasedListFinishedLoadingWithList:(NSArray *)qRBasedList{
    //done loading
    loading = NO;
    [self beaconLoadCheck];
    [self enableAvailableBeaconCell];
}



@end
