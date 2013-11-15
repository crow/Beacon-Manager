//
//  BeaconView.m
//  UABeacons
//
//  Created by David Crow on 10/3/13.
//  Copyright (c) 2013 David Crow. All rights reserved.
//

#import "BeaconViewController.h"
#import "BeaconSettingsViewController.h"

@interface BeaconViewController ()

@end

@implementation BeaconViewController {
    NSMutableDictionary *beacons;
    NSMutableArray *rangedRegions;
    ManagedBeaconRegion *selectedBeaconRegion;
    CLBeacon *selectedBeacon;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        //register for ranging beacons notification
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(managerDidRangeBeacons)
         name:@"managerDidRangeBeacons"
         object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    

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
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    int sections = 1;
    if ([[BeaconRegionManager shared] rangedBeacons].count > 0){
        sections = 2;
    }
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    
    return [[BeaconRegionManager shared] monitoredBeaconRegions].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BeaconCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSArray *monitoredBeaconRegions = [NSArray arrayWithArray:[[[BeaconRegionManager shared] monitoredBeaconRegions] allObjects]];
    selectedBeaconRegion = monitoredBeaconRegions[indexPath.row];
    selectedBeacon = [[BeaconRegionManager shared] beaconWithId:selectedBeaconRegion.identifier];
    // Configure the cell...
    if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
	}
    
    [cell.textLabel setText:selectedBeaconRegion.identifier];
    
    //
    if ([selectedBeacon accuracy]){
        cell.backgroundColor = [UIColor colorWithRed:0 green:100 blue:55 alpha:.2];
    
        [UIView animateWithDuration:1.0 delay:0.f options:UIViewAnimationOptionRepeat
                         animations:^{
                             cell.imageView.alpha=0.2f;
                         } completion:^(BOOL finished){
                             cell.imageView.alpha=1.f;
                         }];
    }
        
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID: %@\nMajor: %@\nMinor: %@\n", [selectedBeaconRegion.proximityUUID UUIDString], selectedBeaconRegion.major ? selectedBeaconRegion.major : @"None", selectedBeaconRegion.minor ? selectedBeaconRegion.minor : @"None"];
    
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
        [vc setBeaconRegion:selectedBeaconRegion];
        [vc setBeacon:selectedBeacon];
        // Pass any objects to the view controller here, like...
        //[vc setMyObjectHere:object];
    }
}

@end
