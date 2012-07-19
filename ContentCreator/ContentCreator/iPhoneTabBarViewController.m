//
//  iPhoneTabBarViewController.m
//  ContentCreator
//
//  Created by Boris on 5/7/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "iPhoneTabBarViewController.h"
#import "Album.h"
#include "globalDefines.h"
#import "FlurryAnalytics.h"
#import "UserData.h"
#import <QuartzCore/QuartzCore.h>
// #import "dlUITabBar.h"
#import "dlLog.h"

#import "ActivityViewController.h"
#import "CuratedViewController.h"
#import "CaptureViewController.h"
#import "NotificationViewController.h"
#import "OptionViewController.h"

#define ACTIVITY_VIEW_CONTROLLER     0
#define CURATED_VIEW_CONTROLLER      1
#define CAPTURE_VIEW_CONTROLLER      2
#define NOTIFICATION_VIEW_CONTROLLER 3 // FIXME
#define OPTION_VIEW_CONTROLLER       3

@interface iPhoneTabBarViewController () <captureViewProtocols, OptionsViewProtocol>

@property (strong, nonatomic) Album * activityAlbum;

@property (strong, nonatomic) ActivityViewController * diaFilmViewController;
@property (strong, nonatomic) CuratedViewController  * curatedViewController;
@property (strong, nonatomic) CaptureViewController * captureViewController;
@property (strong, nonatomic) NotificationViewController * notificationViewController;
@property (strong, nonatomic) OptionViewController * optionViewController;


@property (strong, nonatomic) IBOutlet UITabBar* myTabBar;

@end

@implementation iPhoneTabBarViewController


@synthesize activityAlbum = _activityAlbum;
@synthesize diaFilmViewController = _diaFilmViewController;
@synthesize curatedViewController = _curatedViewController;
@synthesize captureViewController = _captureViewController;
@synthesize notificationViewController = _notificationViewController;
@synthesize optionViewController = _optionViewController;
@synthesize myTabBar = _myTabBar;
@synthesize signupDelegate = _signupDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    [super viewDidLoad];
    
#ifdef VERSION12
    // Some customization of the tab bar
    UIImage *tabBackground = [UIImage imageNamed:@"activity_screen_control_bar.png"];
    [self.myTabBar setBackgroundImage:tabBackground];
    
    self.myTabBar.selectedImageTintColor = UICOLOR_MEMART;
    self.myTabBar.selectionIndicatorImage = nil;
    
    // [self showTabBar];
    
    NSArray * tabBarItems = [self.myTabBar items];
    
    UITabBarItem * activityViewTabBarItem = [tabBarItems objectAtIndex:0];
    UITabBarItem * createViewTabBarItem = [tabBarItems objectAtIndex:1];
    UITabBarItem * optionsViewTabBarItem = [tabBarItems objectAtIndex:2];

    
    [activityViewTabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"tabbar_home_active.png"] 
                         withFinishedUnselectedImage:[UIImage imageNamed:@"tabbar_home_inactive.png"]];
    [activityViewTabBarItem setTitlePositionAdjustment:UIOffsetMake(0.0, +10.0)];
    
    
    [createViewTabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"tabbar_create_active.png"] 
                         withFinishedUnselectedImage:[UIImage imageNamed:@"tabbar_create_inactive.png"]];

    [createViewTabBarItem setTitlePositionAdjustment:UIOffsetMake(0.0, 10.0)];
    
    [optionsViewTabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"tabbar_options_active.png"] 
                         withFinishedUnselectedImage:[UIImage imageNamed:@"tabbar_options_inactive.png"]];
    
    [optionsViewTabBarItem setTitlePositionAdjustment:UIOffsetMake(0.0, 10.0)];
#endif
    
    // FIXME: This is set to 0 based on the assumption that the user will
    // always start on the Activity View screen when the UITabBar is shown
    previousSelectedIndex = 0;
    
    // Have a pointer to all the view controllers so we can programatically
    // manage them
    
    self.diaFilmViewController = [[self viewControllers] objectAtIndex:ACTIVITY_VIEW_CONTROLLER];
//    self.diaFilmViewController.album = [[UserData singleton] publicAlbum]; //userAlbum];
    self.diaFilmViewController.album = [[UserData singleton] userAlbum];
    
    self.curatedViewController = [[self viewControllers] objectAtIndex:CURATED_VIEW_CONTROLLER];
//    self.curatedViewController.album = [[UserData singleton] userAlbum];//publicAlbum];
    self.curatedViewController.album = [[UserData singleton] publicAlbum];
    
    
    self.captureViewController = [[self viewControllers] objectAtIndex:CAPTURE_VIEW_CONTROLLER];
    self.captureViewController.captureViewDelegate = self;

    // self.notificationViewController = [[self viewControllers] objectAtIndex:NOTIFICATION_VIEW_CONTROLLER];
    
    self.optionViewController = [[self viewControllers] objectAtIndex:OPTION_VIEW_CONTROLLER];
    self.optionViewController.delegate = self;

    
    // Set self to be delegate so we can have our own custom controller
    // delegate methods
    [self setDelegate:self];
    
    // Resize the tab bar so that it's a certain pixel height
    [self resizeTabbar];
    
    // This should log all the tab views
    [FlurryAnalytics logAllPageViews:self];
    
    self.selectedIndex = CURATED_VIEW_CONTROLLER;
    [FlurryAnalytics logEvent:@"Curated" timed:YES];
    
}


- (void)viewDidUnload
{
    self.activityAlbum = nil;
    self.diaFilmViewController = nil;
    self.curatedViewController = nil;
    self.captureViewController = nil;
    self.notificationViewController = nil;
    self.optionViewController = nil;

    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/* -------------------------- TAB BAR CONTROLLER DELEGATE METHODS ------------- */
#pragma mark -
#pragma mark TabBarControllerDelegate methods


- (void) tabBarController: (UITabBarController *) tabBarController didSelectViewController: (UIViewController *) viewController
{
    
    int indexSelected = [self selectedIndex];
    
    switch (indexSelected)
    {
        case ACTIVITY_VIEW_CONTROLLER:
            [self.diaFilmViewController displaySelected];
            [self.curatedViewController displayUnselected];
            [self.captureViewController displayUnselected];
            // [self.notificationViewController displayUnselected];
            [self.optionViewController displayUnselected];
            [self showTabBar];
            [FlurryAnalytics logEvent:@"Activity" timed:YES];
            [FlurryAnalytics endTimedEvent:@"Curated" withParameters:nil];
            [FlurryAnalytics endTimedEvent:@"Capture" withParameters:nil];
            [FlurryAnalytics endTimedEvent:@"Options" withParameters:nil];
           
            break;
            
        case CURATED_VIEW_CONTROLLER:
            [self.diaFilmViewController displayUnselected];
            [self.curatedViewController displaySelected];
            [self.captureViewController displayUnselected];
            // [self.notificationViewController displayUnselected];
            [self.optionViewController displayUnselected];
            [self showTabBar];
            [FlurryAnalytics logEvent:@"Curated" timed:YES];
            [FlurryAnalytics endTimedEvent:@"Activity" withParameters:nil];
            [FlurryAnalytics endTimedEvent:@"Capture" withParameters:nil];
            [FlurryAnalytics endTimedEvent:@"Options" withParameters:nil];

            break;
            
        case CAPTURE_VIEW_CONTROLLER:
            [self hideTabBar];
            [self.diaFilmViewController displayUnselected];
            [self.curatedViewController displayUnselected];
            [self.captureViewController displaySelected];
            // [self.notificationViewController displayUnselected];
            [self.optionViewController displayUnselected];
            [FlurryAnalytics logEvent:@"Capture" timed:YES];
            [FlurryAnalytics endTimedEvent:@"Curated" withParameters:nil];
            [FlurryAnalytics endTimedEvent:@"Activity" withParameters:nil];
            [FlurryAnalytics endTimedEvent:@"Options" withParameters:nil];

            break;
            /*
        case NOTIFICATION_VIEW_CONTROLLER:
            [self.diaFilmViewController displayUnselected];
            [self.curatedViewController displayUnselected];
            [self.captureViewController displayUnselected];
             [self.notificationViewController displaySelected];
            [self.optionViewController displayUnselected];
            [self showTabBar];          
            */
            
        case OPTION_VIEW_CONTROLLER:
            [self.diaFilmViewController displayUnselected];
            [self.curatedViewController displayUnselected];
            [self.captureViewController displayUnselected];
            // [self.notificationViewController displayUnselected];
            [self.optionViewController displaySelected];
            [self showTabBar];
            [FlurryAnalytics logEvent:@"Options" timed:YES];
            [FlurryAnalytics endTimedEvent:@"Curated" withParameters:nil];
            [FlurryAnalytics endTimedEvent:@"Capture" withParameters:nil];
            [FlurryAnalytics endTimedEvent:@"Activity" withParameters:nil];

            break;
            
        default:
            dlLogCrit(@"Unknonw viewn Controller selected. Not possible.");
            
            break;
    }
    
}
     
     

- (void) selectDisplay:(int) viewControllerIndex prev:(int) previousSelectedIndex;
{
    return;
}

- (void) unselectDisplay:(int) viewControllerIndex;
{
    return;
}

- (void) terminate
{
    return;
}

- (void) userRequestedFBSignIn
{
    [self setViewControllers:nil animated:NO];    
    
    self.activityAlbum = nil;
    
    self.diaFilmViewController = nil;
    self.captureViewController = nil;
    self.optionViewController = nil;
    self.curatedViewController = nil;
    self.notificationViewController = nil;    
    
    [self.signupDelegate performFBSignIn];    
}

- (void) userRequestedFBSignout
{
    [self setViewControllers:nil animated:NO];    
 
    self.activityAlbum = nil;
    
    self.diaFilmViewController = nil;
    self.captureViewController = nil;
    self.optionViewController = nil;
    self.curatedViewController = nil;
    self.notificationViewController = nil;
    
    [self.signupDelegate performFBSignout];
}


- (void) captureViewDone
{
    [self.captureViewController displayUnselected];
    [self.diaFilmViewController displaySelected];
    [self showTabBar];
   
    self.selectedIndex = 0;
    return;
}


-(void)hideTabBar 
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    for(UIView *view in self.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, 480, view.frame.size.width, 38)];
            
            for( UIView * subview in view.subviews )
            {
                if([subview isKindOfClass:[UITabBarItem class]])
                {
                    [subview setFrame:CGRectMake(view.frame.origin.x, 480, view.frame.size.width, 38)];
                }
            }

        } 
        else 
        {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 480)];
        }
        
    }
    [UIView commitAnimations];
}

- (void) showTabBar
{
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    for(UIView *view in self.view.subviews)
    {
        dlLogDebug(@"%@", view);
        
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, 442, view.frame.size.width, 38)];
            
            for( UIView * subview in view.subviews )
            {
                if([subview isKindOfClass:[UITabBarItem class]])
                {
                    [subview setFrame:CGRectMake(view.frame.origin.x, 442, view.frame.size.width, 38)];
                }
            }
            
        } else {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 442)];
        }        
        
    }
    
    [UIView commitAnimations]; 
}

- (void) resizeTabbar
{
    for(UIView *view in self.view.subviews)
    {
        dlLogDebug(@"%@", view);
        
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setFrame:CGRectMake(view.frame.origin.x, 442, view.frame.size.width, 38)];
            
            for( UIView * subview in view.subviews )
            {
                if([subview isKindOfClass:[UITabBarItem class]])
                {
                    [subview setFrame:CGRectMake(view.frame.origin.x, 442, view.frame.size.width, 38)];
                }
            }
            
        } else {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 442)];
        }        
        
    }
}


@end
