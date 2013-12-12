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
    NSMutableDictionary *beaconStats;
    double lastEntry;
    double lastExit;
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
    self.title = self.managedBeaconRegion.identifier;
    
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
   
    [self.managedBeaconRegion loadSavedBeaconStats];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(managerDidRangeBeacons)
     name:@"managerDidRangeBeacons"
     object:nil];
}



-(void)viewDidDisappear:(BOOL)animated
{
    [self.managedBeaconRegion saveBeaconStats];
}


-(void)loadBeaconStats
{

    if ([[BeaconRegionManager shared] getBeaconStatsForIdentifier:self.managedBeaconRegion.identifier]) {
        beaconStats = [[BeaconRegionManager shared] getBeaconStatsForIdentifier:self.managedBeaconRegion.identifier];
        
        //TODO check type just in case
        if ([beaconStats objectForKey:@"lastEntry"])
        {
            lastEntry = [[beaconStats objectForKey:@"lastEntry"] doubleValue];
            self.lastEntryLabel.text = [NSString stringWithFormat:@"%@", [self dateStringFromInterval:lastEntry]];

        }
        if ([beaconStats objectForKey:@"lastExit"])
        {
            lastExit = [[beaconStats objectForKey:@"lastExit"] doubleValue];
            self.lastExitLabel.text = [NSString stringWithFormat:@"%@", [self dateStringFromInterval:lastExit]];

        }
    }
    
    //only update total last visit time when exit is after entry
    if (lastEntry-lastExit < 0) {
        self.totalLastVisitTimeLabel.text = [NSString stringWithFormat:@"%1.0f Seconds", lastExit-lastEntry];
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

//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:@"yyyy"];
//    
//    //Optionally for time zone converstions
//    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"PDT"]];
//    
//    NSString *stringFromDate = [formatter stringFromDate:dateString];
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
                              initWithTitle:@"Would you like to delete your current statistics data for this beacon?" message:nil delegate:self
                              cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alert show];
    }
    
   //save switch state in NSUserDefaults
    [[NSUserDefaults standardUserDefaults]
     setBool:recordStatsSwitchState forKey:@"recordStatsSwitchState"];
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // the user clicked No
    if (buttonIndex == 0)
    {
        self.managedBeaconRegion.lastEntry = 0;
        self.managedBeaconRegion.lastExit = 0;
    }
    else
    {
    
    }
}



@end
