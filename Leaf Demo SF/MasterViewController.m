//
//  MasterViewController.m
//  Leaf Demo SF
//
//  Created by Erik Risinger on 1/12/14.
//  Copyright (c) 2014 Erik Risinger. All rights reserved.
//

#import "MasterViewController.h"

@interface MasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation MasterViewController

@synthesize photo;
@synthesize firstName;
@synthesize lastName;
@synthesize company;

@synthesize handshakes;

@synthesize targetWatch;

-(void)didSave:(id)sender
{
    SetProfileViewController *newProfile = (SetProfileViewController *)sender;
    self.photo = newProfile.imageView.image;
    self.firstName = newProfile.firstNameField.text;
    self.lastName = newProfile.lastNameField.text;
    self.company = newProfile.companyField.text;
    
    [self.navigationController popViewControllerAnimated:YES];
    [self.tableView reloadData];
    
}

-(void)didCancel
{
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    SetProfileViewController *pvc = nil;
    if ([segue.identifier isEqualToString:@"setProfileSegue"])
    {
        pvc = segue.destinationViewController;
        pvc.delegate = self;
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    self.navigationItem.leftBarButtonItem = self.editButtonItem;
//
//    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
//    self.navigationItem.rightBarButtonItem = addButton;
    
    handshakes = [[NSMutableArray alloc] init];
    
    targetWatch = [[PBPebbleCentral defaultCentral] lastConnectedWatch];
    
    uuid_t myAppUUIDbytes;
    NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:@"1439ea7b-fb74-4583-ad4e-894004371069"];
    [myAppUUID getUUIDBytes:myAppUUIDbytes];
    
    [[PBPebbleCentral defaultCentral] setAppUUID:[NSData dataWithBytes:myAppUUIDbytes length:16]];
    
    [targetWatch appMessagesGetIsSupported:^(PBWatch *watch, BOOL isAppMessagesSupported) {
        if (isAppMessagesSupported) {
            NSLog(@"This Pebble supports app message!");
        }
        else {
            NSLog(@":( - This Pebble does not support app message!");
        }
    }];
    
    [targetWatch appMessagesLaunch:^(PBWatch *watch, NSError *error){
        if (!error) {
            NSLog(@"launched!");
        }
    }];
    
    [targetWatch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update){
        
        //call a method to handle informing the server of a possible handshake -- PENDING
        [self handshakeHandlerWithWatch:watch data:update];
        return YES;
    }];

}

-(void)handshakeHandlerWithWatch:(PBWatch *)watch data:(NSDictionary *)data
{
    if ([[data objectForKey:@(0)] isEqualToString:@"HND"]) {
        
        //time stamp
        NSDate *dateStamp = [NSDate date];
        NSTimeInterval millisecondsSince1970 = [dateStamp timeIntervalSince1970] * 1000;
        
        //user data
        NSString *username = [NSString stringWithFormat:@"%@-%@", firstName, lastName];
        
        if (targetWatch == nil || [targetWatch isConnected] == NO) {
            [[[UIAlertView alloc] initWithTitle:nil message:@"No connected watch!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            NSLog(@"watch not initialized or not connected");
            return;
        }
        
        //handshake
        NSString *apiURLString = [NSString stringWithFormat:@"http://54.215.17.23/send-time?username=%@&timeStamp=%@", username, [NSString stringWithFormat:@"%f",millisecondsSince1970]];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:apiURLString]];
        NSHTTPURLResponse *response = nil;
        NSError *error = nil;
        NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        // Parse the JSON response:
        NSDictionary *serverResponse = [NSJSONSerialization JSONObjectWithData:result options:0 error:&error];
        @try {
            if (serverResponse && result) {
                
                NSError *jsonError = nil;
                NSDictionary *serverResponse = [NSJSONSerialization JSONObjectWithData:result options:0 error:&jsonError];
                // TODO: type checking / validation, this is really dangerous...
                
                [NSThread sleepForTimeInterval:2];
                apiURLString = [NSString stringWithFormat:@"http://54.215.17.23/users?username=%@", username];
                request = [NSURLRequest requestWithURL:[NSURL URLWithString:apiURLString]];
                response = nil;
                error = nil;
                result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                NSLog(@"%@", result);
                
                serverResponse = [NSJSONSerialization JSONObjectWithData:result options:0 error:&jsonError];
                
                //parse out and store names
                handshakes = [[NSMutableArray alloc] init];
                
                NSArray *names = [serverResponse objectForKey:@"message"];
                
                NSArray *firstAndLast;
                NSString *first = @"";
                NSString *last = @"";
                
                for (NSString *name in names)
                {
                    firstAndLast = [name componentsSeparatedByString:@"-"];
                    first = [firstAndLast objectAtIndex:0];
                    last = [firstAndLast objectAtIndex:1];
                    
                    //add to handshakes
                    [handshakes addObject:[NSDictionary dictionaryWithObjectsAndKeys:[[UIImage alloc] init], @"photo", first, @"firstName", last, @"lastName", @"", @"company", nil]];
                }
                
                [self.tableView reloadData];
                
                //send to pebble
                NSDictionary *update = [NSDictionary dictionaryWithObjectsAndKeys:first, @(0), last, @(1), nil];
                [targetWatch appMessagesPushUpdate:update onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
                    if (error) {
                        NSLog(@"received info from server, pushed to watch");
                    }
                }];
                
                return;
            }
        }
        @catch (NSException *exception) {
        }


    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
         // Replace this implementation with code to handle the error appropriately.
         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//    return [[self.fetchedResultsController sections] count];
    return handshakes.count > 0 ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
//    return [sectionInfo numberOfObjects];
    
    if (section == 0) { return 1; }
    else{ return handshakes.count; }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"My profile" : @"Handshakes";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
//    [self configureCell:cell atIndexPath:indexPath];
    NSString *cellIdentifier = @"";
    
    if (indexPath.section == 0) { cellIdentifier = @"ProfileCell"; }
    else { cellIdentifier = @"HandshakeCell"; }
    
    ProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) { cell = [[ProfileCell alloc] init]; }
    
    if (indexPath.section == 0)
    {
        if (photo) {
            cell.imageView.image = photo;
        }
        if (firstName || lastName) {
            cell.nameLabel.text = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            cell.companyLabel.text = company;
        }
        else
        {
            cell.nameLabel.text = @"My profile";
            cell.companyLabel.text = @"Press to set";
        }
    }
    
    else
    {
        NSDictionary *dict = [handshakes objectAtIndex:indexPath.row];
        cell.imageView.image = [dict objectForKey:@"photo"];
        cell.nameLabel.text = [NSString stringWithFormat:@"%@ %@", [dict objectForKey:@"firstName"], [dict objectForKey:@"lastName"]];
        cell.companyLabel.text = [dict objectForKey:@"company"];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
}

@end
