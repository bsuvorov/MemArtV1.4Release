//
//  FullscreenViewController.m
//  MemArt
//
//  Created by Aashish Patel on 7/11/12.
//  Copyright (c) 2012 Mulishani LLC. All rights reserved.
//

#import "FullscreenViewController.h"

@interface FullscreenViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *diaFilmImageView;
@property (weak, nonatomic) IBOutlet UIButton *btnExitView;

@end

@implementation FullscreenViewController
@synthesize diaFilmImageView;
@synthesize btnExitView;
@synthesize fullscreenDelegate;


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
    [self setDiaFilmImageView:nil];
    [self setBtnExitView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) exitPressed:(UIButton *) sender
{
    [self.fullscreenDelegate fullscreenExit];
    return;
}

@end
