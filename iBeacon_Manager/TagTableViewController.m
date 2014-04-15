/*
 Copyright 2009-2013 Urban Airship Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "TagTableViewController.h"

#import "UAPush.h"

@interface TagTableViewController ()

@property (nonatomic, strong) NSMutableArray *currentTags;

@end

@implementation TagTableViewController

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
    self.currentTags = [NSMutableArray arrayWithArray:[UAPush shared].tags];

    //default to editing, since the view is for adding/removing tags
    self.editing = YES;
    [self.tableView reloadData];
    [super viewWillAppear:animated];

}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return [self.currentTags count] + 1;//add one for the add tag cell
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = nil;

    if (indexPath.row == [self.currentTags count]) { //add tag
        cell = [tableView dequeueReusableCellWithIdentifier:@"addTagCell" forIndexPath:indexPath];
    } else { // existing tag
        cell = [tableView dequeueReusableCellWithIdentifier:@"tagCell" forIndexPath:indexPath];

        // Configure the cell...
        cell.textLabel.text = [self.currentTags objectAtIndex:indexPath.row];
    }
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.currentTags count]) {
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


        NSString *tagToDelete = [self.currentTags objectAtIndex:(NSUInteger)indexPath.row];


        // Commit to server
        [[UAPush shared] removeTagFromCurrentDevice:tagToDelete];
        [[UAPush shared] updateRegistration];

        // Delete the row from the data source & local copy of tags
        [self.currentTags removeObjectAtIndex:(NSUInteger)indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];

    } else if (editingStyle == UITableViewCellEditingStyleInsert) {

        UITextField *tagEditField = (UITextField *)[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:2];

        NSString *tagToAdd = tagEditField.text;
        if (tagToAdd && tagToAdd.length > 0 && ![self.currentTags containsObject:tagToAdd]) {
            [[UAPush shared] addTagToCurrentDevice:tagToAdd];
            [[UAPush shared] updateRegistration];

            tagEditField.text = nil;

            // Insert the row to the data source & update local copy
            [self.currentTags addObject:tagToAdd];
            [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
        }
    }
}

@end
