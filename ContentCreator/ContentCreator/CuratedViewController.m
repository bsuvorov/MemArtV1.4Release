//
//  CuratedViewController.m
//  MemArt
//
//  Created by Aashish Patel on 7/11/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "CuratedViewController.h"

@interface CuratedViewController ()

@end

@implementation CuratedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) displaySelected
{
    
}

- (void) displayUnselected
{
    
}

@end
