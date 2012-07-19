//
//  dlUITabBar.m
//  ContentCreator
//
//  Created by Aashish Patel on 6/1/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "dlUITabBar.h"

@implementation dlUITabBar

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

- (void)drawRect:(CGRect)rect 
{
    CGRect newFrame = CGRectMake(self.frame.origin.x, 442, self.frame.size.width, 38 );
    self.frame = newFrame;
    [super drawRect:rect];
    return;
}

@end
