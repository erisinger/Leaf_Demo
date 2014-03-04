//
//  MasterViewController.h
//  Leaf Demo SF
//
//  Created by Erik Risinger on 1/12/14.
//  Copyright (c) 2014 Erik Risinger. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>
#import "SetProfileViewController.h"
#import "ProfileCell.h"
#import <PebbleKit/PebbleKit.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, SetSFProfileDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *company;

@property (nonatomic, strong) NSMutableArray *handshakes;

@property (nonatomic, strong) PBWatch *targetWatch;

-(void)didSave:(id)sender;
-(void)didCancel;

@end
