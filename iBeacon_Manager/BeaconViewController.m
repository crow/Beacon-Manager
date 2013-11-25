//
//  BeaconView.m
//  UABeacons
//
//  Created by David Crow on 10/3/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "BeaconViewController.h"
#import "BeaconSettingsViewController.h"
//remove this after debugging
#import "PlistManager.h"

@interface BeaconViewController ()

@end

@implementation BeaconViewController
{
    NSMutableDictionary *beacons;
  //  NSMutableArray *rangedRegions;
    ManagedBeaconRegion *currentManagedBeaconRegion;
    CLBeacon *selectedBeacon;
    int hitCount;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //register for ranging beacons notification
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(managerDidRangeBeacons)
     name:@"managerDidRangeBeacons"
     object:nil];
    hitCount = 0;
}

-(void)viewWillAppear
{
    [self.tableView reloadData];
}

- (void)managerDidRangeBeacons
{
    hitCount++;
    if (hitCount>5){
        [self.tableView reloadData];
        hitCount = 0;
    }
    

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    int sections = 1;

    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[BeaconRegionManager shared] availableManagedBeaconRegions].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BeaconCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    

    NSArray *availableManagedBeaconRegions = [[BeaconRegionManager shared] availableManagedBeaconRegions]; //[NSArray arrayWithArray:[[[BeaconRegionManager shared] monitoredBeaconRegions] allObjects]];
    
    currentManagedBeaconRegion = availableManagedBeaconRegions[indexPath.row];
    // Configure the cell...
    if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
    
    [cell.textLabel setText:currentManagedBeaconRegion.identifier];
    
    //if this beacon is in range
    if ([currentManagedBeaconRegion.beacon accuracy]){
        UIImage *greenMarker = [[UIImage alloc] init];
        greenMarker = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"722-location-ping@2x" ofType:@"png"]];
        cell.imageView.image = greenMarker;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID: %@\nMajor: %@\nMinor: %@\n", [currentManagedBeaconRegion.proximityUUID UUIDString], currentManagedBeaconRegion.major ? currentManagedBeaconRegion.major : @"None", currentManagedBeaconRegion.minor ? currentManagedBeaconRegion.minor : @"None"];

        //animation is freezing every other refresh
//        [UIView animateWithDuration:1.0 delay:0.f options:UIViewAnimationOptionRepeat
//                         animations:^{
//                             cell.imageView.alpha=0.6f;
//                         } completion:^(BOOL finished){
//                             cell.imageView.alpha=1.f;
//                         }];
     
    }
    else if ([currentManagedBeaconRegion.beacon rssi] == -1.000){
        UIImage *blackMarker = [[UIImage alloc] init];
        blackMarker = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"location-pin-selected" ofType:@"png"]];
        cell.imageView.image = blackMarker;
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID: %@\nMajor: %@\nMinor: %@\n", [currentManagedBeaconRegion.proximityUUID UUIDString], currentManagedBeaconRegion.major ? currentManagedBeaconRegion.major : @"None", currentManagedBeaconRegion.minor ? currentManagedBeaconRegion.minor : @"None"];
    }
    else{
        UIImage *whiteMarker = [[UIImage alloc] init];
        whiteMarker = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"722-location-pin@2x" ofType:@"png"]];
        cell.imageView.image = whiteMarker;
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID: %@\nMajor: %@\nMinor: %@\n", [currentManagedBeaconRegion.proximityUUID UUIDString], currentManagedBeaconRegion.major ? currentManagedBeaconRegion.major : @"None", currentManagedBeaconRegion.minor ? currentManagedBeaconRegion.minor : @"None"];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //update selected beacon region
    currentManagedBeaconRegion = [[BeaconRegionManager shared] beaconRegionWithId:cell.textLabel.text];
    [self performSegueWithIdentifier:@"beaconSettings" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"beaconSettings"])
    {
        // Get reference to the destination view controller
        BeaconSettingsViewController *vc = [segue destinationViewController];

        vc.beaconRegion = currentManagedBeaconRegion;
        vc.beacon = currentManagedBeaconRegion.beacon;

        // Pass any objects to the view controller here, like...
        //[vc setMyObjectHere:object];
    }
}

@end
