//
//  ProfileCell.m
//  Leaf Demo SF
//
//  Created by Erik Risinger on 1/12/14.
//  Copyright (c) 2014 Erik Risinger. All rights reserved.
//

#import "ProfileCell.h"

@implementation ProfileCell

@synthesize imageView;
@synthesize nameLabel;
@synthesize companyLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
