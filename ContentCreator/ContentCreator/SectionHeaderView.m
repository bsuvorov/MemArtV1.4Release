//
//  SectionHeaderView.m
//  ContentCreator
//
//  Created by Aashish Patel on 6/22/12.
//  Copyright (c) 2012 Mulishani LLC. All rights reserved.
//

#import "SectionHeaderView.h"

@implementation SectionHeaderView

@synthesize lblUsername = _lblUsername;
@synthesize lblTimetaken = _lblTimetaken;
@synthesize ivUserpic = _ivUserpic;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
