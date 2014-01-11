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
#import "BeaconPlistManager.h"

@interface BeaconViewController ()

@end

@implementation BeaconViewController
{
    NSMutableDictionary *_beacons;
    CLBeaconRegion *_selectedBeaconRegion;
    CLBeacon *_selectedBeacon;
    UIImage *_whiteMarker;
    UIImage *_greenMarker;
    int _refreshCount;
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

    //Load the available managed beacon regions and update monitored regions
    [[BeaconRegionManager shared] loadAvailableRegions];
    [[BeaconRegionManager shared] syncMonitoredRegions];

    [[BeaconRegionManager shared] startManager];
    
    //Initialize reused tableview images
    _greenMarker = [[UIImage alloc] init];
    _greenMarker = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"722-location-ping@2x" ofType:@"png"]];
    
    _whiteMarker = [[UIImage alloc] init];
    _whiteMarker = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"722-location-pin@2x" ofType:@"png"]];
    
    //register for ranging beacons notification
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(managerDidRangeBeacons)
     name:@"managerDidRangeBeacons"
     object:nil];
    
    _selectedBeacon = [[CLBeacon alloc] init];
    _selectedBeaconRegion = [[CLBeaconRegion alloc] init];
    
    _refreshCount = 0;
}

- (void)managerDidRangeBeacons
{
    //reloads every 3 seconds for better responsiveness w/o table view jerk
    if (_refreshCount > 2){
        _refreshCount = 0;
        [self.tableView reloadData];
    }
    _refreshCount++;
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
    return [[BeaconRegionManager shared] availableBeaconRegionsList].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BeaconCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
 
    NSArray *availableBeaconRegionsList = [[BeaconRegionManager shared] availableBeaconRegionsList]; //[NSArray arrayWithArray:[[[BeaconRegionManager shared] monitoredBeaconRegions] allObjects]];
    
    CLBeaconRegion *selectedBeaconRegion = availableBeaconRegionsList[indexPath.row];
    CLBeacon *selectedBeacon = [[BeaconRegionManager shared] beaconWithId:[availableBeaconRegionsList[indexPath.row] identifier]];
    
    // Configure the cell...
    if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
    
    [cell.textLabel setText:selectedBeaconRegion.identifier];
    
    //iBeacon is in range
    if ([selectedBeacon accuracy] > 0)
    {
        cell.imageView.image = _greenMarker;
    }
    //iBeacon has been seen, but has gone out of range
    else if ([selectedBeacon accuracy] == -1)
    {
        //fade green marker to white
        [UIView animateWithDuration:1.0 delay:0.f options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                         animations:^{
                             cell.imageView.image = _whiteMarker;
                         } completion:^(BOOL finished){
                             cell.imageView.alpha=1.f;
                         }];
    }
    //iBeacon has never been seen
    else{
        cell.imageView.image = _whiteMarker;
    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID: %@\nMajor: %@\nMinor: %@\n", [selectedBeaconRegion.proximityUUID UUIDString], selectedBeaconRegion.major ? selectedBeaconRegion.major : @"None", selectedBeaconRegion.minor ? selectedBeaconRegion.minor : @"None"];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //NOTE setting the selected beacon region and selected beacon in this way will cause issue if IDs are not unique
    _selectedBeaconRegion = [[BeaconRegionManager shared] beaconRegionWithId:cell.textLabel.text];
    _selectedBeacon = [[BeaconRegionManager shared] beaconWithId:cell.textLabel.text];
    [self performSegueWithIdentifier:@"beaconSettings" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"beaconSettings"])
    {
        // Get reference to the destination view controller
        BeaconSettingsViewController *vc = [segue destinationViewController];

        vc.beaconRegion = _selectedBeaconRegion;
        vc.beacon = _selectedBeacon;
    }
}

@end
