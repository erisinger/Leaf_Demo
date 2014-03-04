//
//  ProfileCell.h
//  Leaf Demo SF
//
//  Created by Erik Risinger on 1/12/14.
//  Copyright (c) 2014 Erik Risinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *companyLabel;

@end
