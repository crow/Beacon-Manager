//
//  BeaconStatsViewController.m
//  iBeacon_Manager
//
//  Created by David Crow on 11/14/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "BeaconStatsViewController.h"

@interface BeaconStatsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *cumulativeVisitTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastExitLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastEntryLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalLastVisitTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalVisitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *averageVisitTimeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *recordStatsSwitch;

@end

@implementation BeaconStatsViewController {
   @private
        NSMutableDictionary *_beaconStats;
        double _lastEntry;
        double _lastExit;
        double _cumulativeVisitTime;
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
    [super viewDidLoad];
    self.title = self.beaconRegion.identifier;
    
    BOOL recordState;
    if ([[NSUserDefaults standardUserDefaults]
          boolForKey:@"recordStatsSwitchState"]){
        recordState = [[NSUserDefaults standardUserDefaults]
                            boolForKey:@"recordStatsSwitchState"];
    }
    else{
        recordState = YES;
    }
    
    //used saved entry unless saved entry is nil
    recordState ? [self.recordStatsSwitch setEnabled:recordState] : [self.recordStatsSwitch setEnabled:YES];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(managerDidRangeBeacons)
     name:@"managerDidRangeBeacons"
     object:nil];
}

-(void)viewDidDisappear:(BOOL)animated
{

}

-(void)loadBeaconStats
{
    
    _lastEntry = [[BeaconRegionManager shared] lastEntryForIdentifier:self.beaconRegion.identifier];
    _lastExit = [[BeaconRegionManager shared] lastExitForIdentifier:self.beaconRegion.identifier];
    _cumulativeVisitTime = [[BeaconRegionManager shared] cumulativeTimeForIdentifier:self.beaconRegion.identifier];
    
    self.lastEntryLabel.text = _lastEntry == 0 ? @"---" : [NSString stringWithFormat:@"%@",[self dateStringFromInterval:_lastEntry]];
    self.lastExitLabel.text = _lastExit == 0 ? @"---" : [NSString stringWithFormat:@"%@",[self dateStringFromInterval:_lastExit]];
    self.cumulativeVisitTimeLabel.text = _cumulativeVisitTime == 0 ? @"---" : [NSString stringWithFormat:@"%1.0f Seconds", _cumulativeVisitTime];
    
    //only update total last visit time when exit is after entry
    if (_lastExit-_lastEntry > 0) {
        self.totalLastVisitTimeLabel.text = [NSString stringWithFormat:@"%1.0f Seconds", _lastExit-_lastEntry];
    }
    else {
        self.totalLastVisitTimeLabel.text = [NSString stringWithFormat:@"Waiting for exit..."];
    }
}

- (void)managerDidRangeBeacons
{
    //continuosly update beaconstats
    [self loadBeaconStats];
}

-(NSString *)dateStringFromInterval:(NSTimeInterval)interval
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    NSString *dateString = [NSDateFormatter localizedStringFromDate:date
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterShortStyle];
    return dateString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
- (IBAction)recordStatsSwitchTouched:(id)sender
{
    BOOL recordStatsSwitchState = [sender isOn];

    if (recordStatsSwitchState)
    {
        NSLog(@"Recording Started");
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Would you like to delete your current statistics data?" message:nil delegate:self
                              cancelButtonTitle:@"No" otherButtonTitles:@"Yes, for this beacon", @"Yes, all stats", nil];
        [alert show];
    }
   //save switch state in NSUserDefaults
    [[NSUserDefaults standardUserDefaults]
     setBool:recordStatsSwitchState forKey:@"recordStatsSwitchState"];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
            //delete all stats for this beacon
            [[BeaconRegionManager shared] clearBeaconStatsForBeaconRegion:self.beaconRegion];
            break;
        case 2:
            //delete all stats
            [[BeaconRegionManager shared] clearBeaconStats];
            break;
        default:
            //do nothing (user said no)
            break;
    }
    // the user clicked No
    if (buttonIndex == 0)
    {

    }
    if (buttonIndex == 1)
    {
        
    }
    else
    {
        [[BeaconRegionManager shared] clearBeaconStats];
    }
}

@end
