//
//  NotificationViewCell.m
//  MemArt
//
//  Created by Aashish Patel on 7/12/12.
//  Copyright (c) 2012 Mulishani LLC. All rights reserved.
//

#import "NotificationViewCell.h"

@interface NotificationViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *ivCommenter;
@property (weak, nonatomic) IBOutlet UIImageView *ivDiaFilmThumb;
@property (weak, nonatomic) IBOutlet UITextView *notificationText;

@end

@implementation NotificationViewCell
@synthesize ivCommenter;
@synthesize ivDiaFilmThumb;
@synthesize notificationText;

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
