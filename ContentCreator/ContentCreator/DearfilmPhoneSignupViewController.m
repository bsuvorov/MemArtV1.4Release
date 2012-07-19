//
//  DearfilmPhoneSignupViewController.m
//  ContentCreator
//
//  Created by Boris on 5/7/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "DearfilmPhoneSignupViewController.h"
#import "ActivityViewController.h"
#import <Parse/Parse.h>
#import "globalDefines.h"
#import "UserData.h"
#import "DemoActivityWithSignIn.h"
#import "dlLog.h"
#import "iPhoneTabBarViewController.h"
#import "DiafilmFSSaver.h"
#import "CDCleaner.h"
#import "FlurryAnalytics.h"

#define DEBUG_SIGNUP 1

@interface DearfilmPhoneSignupViewController () <TabBarProtocol, DemoActivityFBSignUp, UserDataloginDelegate, UserDataFriendsIDsDelegate>

@property BOOL returnedWithFBSignInRequest;
@property BOOL returnedWithFBSignOutRequest;
@property BOOL justSignedIn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *isFBloadedSpinner;
@property (strong, nonatomic) DemoActivityWithSignIn * demoController;
@property (weak, nonatomic) iPhoneTabBarViewController * tabBarController;
@end

@implementation DearfilmPhoneSignupViewController

@synthesize isFBloadedSpinner = _isFBloadedSpinner;
@synthesize demoController = _demoController;
@synthesize tabBarController = _tabBarController;
@synthesize justSignedIn = _justSignedIn;
@synthesize returnedWithFBSignInRequest = _returnedWithFBSignInRequest;
@synthesize returnedWithFBSignOutRequest = _returnedWithFBSignOutRequest;

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
    self.returnedWithFBSignInRequest = NO;
    self.returnedWithFBSignOutRequest = NO;
    self.justSignedIn = NO;
}


-(void)viewDidAppear:(BOOL)animated
{
    UserData * ud = [UserData singleton];
    
    ud.loginDelegate = self;
    // if we're just loading to app
    if (!self.returnedWithFBSignInRequest && !self.returnedWithFBSignOutRequest)
    {
        [ud prepareDatabase];
    }
}

- (void)viewDidUnload
{
    [self setIsFBloadedSpinner:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"FBLoginSeg"]) {
        self.tabBarController = segue.destinationViewController;
        self.tabBarController.signupDelegate = self;
        
        // this is safety check to ensure that all our segues are corretly named,
        // even though some of them don't need any special settings
        return;
    }
    
    NSAssert(0, @"%s:Can't find segue name", __FUNCTION__);
}

- (void) moveToMainActivity
{    
    self.returnedWithFBSignOutRequest = NO;
    self.returnedWithFBSignInRequest = NO;
    UserData * ud = [UserData singleton];

    if (self.justSignedIn)
    {
        [ud.publicAlbum startAsyncLoadFromAllSourcesForNextXDiafilms:FIRST_EVER_LOAD_ALBUM_SIZE_ON];        
        [ud.userAlbum startAsyncLoadFromAllSourcesForNextXDiafilms:FIRST_EVER_LOAD_ALBUM_SIZE_ON];
    }
    else
    {
        [ud.userAlbum startAsyncLoadfFromLocalStorageXDiafilms:DEFAULT_ALBUM_NEXT_FETCH_SIZE];
        [ud.publicAlbum startAsyncLoadFromAllSourcesForNextXDiafilms:FIRST_EVER_LOAD_ALBUM_SIZE_ON];
    }

    
    [self stopAnimatingAndSegue];
}

- (void) stopAnimatingAndSegue
{
    [self.isFBloadedSpinner stopAnimating];
    [self performSegueWithIdentifier:@"FBLoginSeg" sender:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentlyDownloading"])
    {
        if ([object currentlyDownloading] == NO) 
        {
            if ([NSThread isMainThread])
                [self stopAnimatingAndSegue];
            else 
                dispatch_sync(dispatch_get_main_queue(), ^{[self stopAnimatingAndSegue];});
        }
        return;
    }
    NSAssert(0, @"check if observer needs to change name of property");
}


- (void) userRequestedFBLogin
{    
    [self.isFBloadedSpinner startAnimating];    
    UserData * ud = [UserData resetSingleton];
    ud.loginDelegate = self;
    ud.friendsDelegate = self;
    [ud loginWithFacebook];   
}

- (void) userSignedInWithStatus:(BOOL) success
{
    UserData * ud = [UserData singleton];
    
    if (!success) 
    {
        dlLogCrit(@"Failed to sign in with Facebook");
        [FlurryAnalytics logEvent:@"FB FAIL"];
        [ud prepareDatabase];
    }
    [FlurryAnalytics logEvent:@"FB PASS"];
    self.justSignedIn = YES;
    
    if (success && ud.userFriendsIDsReady)
        [ud prepareDatabase];
}

- (void) userFriendsRefreshedWithStatus:(BOOL) success FriendListHasChanged: (BOOL) listHasChanged
{
    UserData * ud = [UserData singleton];
    
    if (!success)
        dlLogWarn(@"Failed to get facebook friends from user");

    if (ud.friendsDelegate == self)
        ud.friendsDelegate = nil;
    
    if (success && ud.userIDReady)
        [ud prepareDatabase];
    
}

- (void) performFBSignIn
{
    self.returnedWithFBSignInRequest = YES;
    [self.tabBarController dismissViewControllerAnimated:NO completion:^{    
        [self userRequestedFBLogin];
    }];
}

- (void) performFBSignout
{
    self.returnedWithFBSignOutRequest = YES;
    [self.tabBarController dismissViewControllerAnimated:NO completion:^{    
        UserData *ud = [UserData singleton];    
        [ud logOutAndRemoveUserDataWithCompletionBlock:^(BOOL success)
         {             
             UserData * ud = [UserData resetSingleton];
             ud.loginDelegate = self;
             [ud prepareDatabase];
         }];             
     }];

}

- (void) userDataPreLoaded: (BOOL) success
{
    UserData * ud = [UserData singleton];
    
    [CDCleaner cleanupDatabaseWithCompletionBlock:^(BOOL success)
     {
         dlLogInfo(@"Finished cleanup of core data"); 
     }];
    
    if (ud.loginDelegate == self)
        ud.loginDelegate = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self moveToMainActivity];
    });
}

@end





 