//
//  SetProfileViewController.h
//  Leaf Demo SF
//
//  Created by Erik Risinger on 1/12/14.
//  Copyright (c) 2014 Erik Risinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SetSFProfileDelegate <NSObject>

-(void)didSave:(id)sender;
-(void)didCancel;

@end

@interface SetProfileViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) id<SetSFProfileDelegate> delegate;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UITextField *firstNameField;
@property (nonatomic, weak) IBOutlet UITextField *lastNameField;
@property (nonatomic, weak) IBOutlet UITextField *companyField;

-(IBAction)didPressSave;
-(IBAction)didPressCancel;

@end
