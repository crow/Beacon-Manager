//
//  EntryTagsTableViewController.m
//  UA_Beacon_Manager
//
//  Created by David Crow on 4/17/14.
//  Copyright (c) 2014 David Crow. All rights reserved.
//

#import "EntryTagsTableViewController.h"
#import "BeaconRegionManager.h"
#import "UAPush.h"

@interface EntryTagsTableViewController ()

@property (nonatomic, strong) NSMutableArray *currentEntryTags;

@end

@implementation EntryTagsTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
    // keep a local copy here because the order of the UAPush tags is not guaranteed
    // we don't want the UI to shuffle all the time, so we'll keep our own order
    self.currentEntryTags = [NSMutableArray arrayWithArray:[[BeaconRegionManager shared] entryTagsForBeaconRegion:self.beaconRegion]];
    
    //default to editing, since the view is for adding/removing tags
    self.editing = YES;
    [self.tableView reloadData];
    [super viewWillAppear:animated];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //generate key to store tags based on beacon identifier
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillDisappear:(BOOL)animated {
 
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return [self.currentEntryTags count] + 1;//add one for the add tag cell
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    if (indexPath.row == [self.currentEntryTags count]) { //add tag
        cell = [tableView dequeueReusableCellWithIdentifier:@"addTagCell" forIndexPath:indexPath];
    } else { // existing tag
        cell = [tableView dequeueReusableCellWithIdentifier:@"tagCell" forIndexPath:indexPath];
        
        // Configure the cell...
        cell.textLabel.text = [self.currentEntryTags objectAtIndex:indexPath.row];
    }
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.currentEntryTags count]) {
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        
        NSString *tagToDelete = [self.currentEntryTags objectAtIndex:(NSUInteger)indexPath.row];
        
        //TODO store this key as a constant if possible
        NSString *beaconEntryTagsKey = [NSString stringWithFormat:@"ua-beaconmanager-%@-entry-tags",self.beaconRegion.identifier];
        
        //Remove the tag from the table view from NSUserDefaults entry tags store and re-save the entry
        NSMutableArray *entryTags = [NSMutableArray arrayWithArray:[[BeaconRegionManager shared] entryTagsForBeaconRegion:self.beaconRegion]];
        [entryTags removeObject:tagToDelete];
        [[NSUserDefaults standardUserDefaults] setObject:entryTags forKey:beaconEntryTagsKey];
    
        // Delete the row from the data source & local copy of tags
        [self.currentEntryTags removeObjectAtIndex:(NSUInteger)indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
        UITextField *tagEditField = (UITextField *)[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:2];
        
        NSString *tagToAdd = tagEditField.text;
        if (tagToAdd && tagToAdd.length > 0 && ![self.currentEntryTags containsObject:tagToAdd]) {
            //TODO store this key as a constant if possible
            NSString *beaconEntryTagsKey = [NSString stringWithFormat:@"ua-beaconmanager-%@-entry-tags",self.beaconRegion.identifier];
            
            //Add the tag from the table view to NSUserDefaults entry tags store and re-save the entry
            NSMutableArray *entryTags = [NSMutableArray arrayWithArray:[[BeaconRegionManager shared] entryTagsForBeaconRegion:self.beaconRegion]];
            [entryTags addObject:tagToAdd];
            [[NSUserDefaults standardUserDefaults] setObject:entryTags forKey:beaconEntryTagsKey];
            
            tagEditField.text = nil;
            
            // Insert the row to the data source & update local copy
            [self.currentEntryTags addObject:tagToAdd];
            [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
        }
    }
}

@end
