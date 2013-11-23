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

@implementation BeaconStatsViewController 

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
    BOOL recordState = [[NSUserDefaults standardUserDefaults]
                        boolForKey:@"recordStatsSwitchState"];
    
    //used saved entry unless saved entry is nil
    recordState ? [self.recordStatsSwitch setEnabled:recordState] : [self.recordStatsSwitch setEnabled:YES];
   
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(managerDidRangeBeacons)
     name:@"managerDidRangeBeacons"
     object:nil];
    
    
}

- (void)managerDidRangeBeacons
{

  
    self.lastEntryLabel.text = [self dateStringFromInterval:[[NSDate date] timeIntervalSince1970]];
    //self.lastExitLabel.text = [self dateStringFromInterval:self.beaconRegion.lastExit];
    self.totalLastVisitTimeLabel.text = [NSString stringWithFormat:@"%f",
                                                                  [[NSDate date] timeIntervalSince1970]];
    
}

-(NSString *)dateStringFromInterval:(NSTimeInterval)interval{
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
    // Dispose of any resources that can be recreated.
}
- (IBAction)recordStatsSwitchTouched:(id)sender {
    BOOL recordStatsSwitchState = [sender isOn];

    if (recordStatsSwitchState) {
        NSLog(@"Recording Started");
    }
    else {
        
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Would you like to delete your current statistics data for this beacon?" message:nil delegate:self
                              cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alert show];
    }
    
   //save switch state in NSUserDefaults
    [[NSUserDefaults standardUserDefaults]
     setBool:recordStatsSwitchState forKey:@"recordStatsSwitchState"];
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;{
    // the user clicked No
    if (buttonIndex == 0)
    {
        self.beaconRegion.lastEntry = 0;
        self.beaconRegion.lastExit = 0;
    }
    else{
    
    }
}



@end
