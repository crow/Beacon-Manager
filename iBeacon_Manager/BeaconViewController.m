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

@implementation BeaconViewController {
    NSMutableDictionary *beacons;
  //  NSMutableArray *rangedRegions;
    ManagedBeaconRegion *selectedBeaconRegion;
    CLBeacon *selectedBeacon;
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
}

-(void)viewWillAppear
{
    [self.tableView reloadData];
}

- (void)managerDidRangeBeacons
{


    
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
    return [[BeaconRegionManager shared] availableBeaconRegions].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BeaconCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSArray *availableBeaconRegions = [[BeaconRegionManager shared] availableBeaconRegions]; //[NSArray arrayWithArray:[[[BeaconRegionManager shared] monitoredBeaconRegions] allObjects]];
    
    selectedBeaconRegion = availableBeaconRegions[indexPath.row];
    // Configure the cell...
    if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
    
    [cell.textLabel setText:selectedBeaconRegion.identifier];
    
    //if this beacon is in range
    if ([selectedBeaconRegion.beacon accuracy]){
        UIImage *greenMarker = [[UIImage alloc] init];
        greenMarker = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"722-location-ping@2x" ofType:@"png"]];
        cell.imageView.image = greenMarker;

        //animation is freezing every other refresh
//        [UIView animateWithDuration:1.0 delay:0.f options:UIViewAnimationOptionRepeat
//                         animations:^{
//                             cell.imageView.alpha=0.2f;
//                         } completion:^(BOOL finished){
//                             cell.imageView.alpha=1.f;
//                         }];

    }
    else{
        cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID: %@\nMajor: %@\nMinor: %@\n", [selectedBeaconRegion.proximityUUID UUIDString], selectedBeaconRegion.major ? selectedBeaconRegion.major : @"None", selectedBeaconRegion.minor ? selectedBeaconRegion.minor : @"None"];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //update selected beacon region
    selectedBeaconRegion = [[BeaconRegionManager shared] beaconRegionWithId:cell.textLabel.text];
    [self performSegueWithIdentifier:@"beaconSettings" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"beaconSettings"])
    {
        // Get reference to the destination view controller
        BeaconSettingsViewController *vc = [segue destinationViewController];
        vc.beaconRegion = selectedBeaconRegion;
        vc.beacon = selectedBeaconRegion.beacon;
        // Pass any objects to the view controller here, like...
        //[vc setMyObjectHere:object];
    }
}

@end
