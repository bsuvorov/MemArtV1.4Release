//
//  OptionViewController.m
//  ContentCreator
//
//  Created by Aashish Patel on 5/14/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "OptionViewController.h"
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Parse/Parse.h>
#import "globalDefines.h"
#import "UserData.h"
#import "FAQViewController.h"
#import "FlurryAnalytics.h"
#import "dlLog.h"

@interface OptionViewController () <UIActionSheetDelegate, FAQProtocol>

@property (weak, nonatomic) IBOutlet UISlider *sldCountdown;
@property (weak, nonatomic) IBOutlet UILabel *lblCountdownValue;
@property (weak, nonatomic) IBOutlet UILabel *appVersionString;
@property (weak, nonatomic) IBOutlet UIButton *btnFBSignIn;
@property (weak, nonatomic) IBOutlet UIButton *fbLogout;
@property (weak, nonatomic) IBOutlet UIButton *btnWhySignIn;
@property (weak, nonatomic) FAQViewController *faqVC;
@property (weak, nonatomic) IBOutlet UILabel *lblSignInType;
@property (weak, nonatomic) IBOutlet UILabel *lblSignInName;
@end

@implementation OptionViewController

@synthesize sldCountdown = _sldCountdown;
@synthesize lblCountdownValue = _lblCountdownValue;
@synthesize appVersionString = _appVersionString;
@synthesize btnFBSignIn = _btnFBSignIn;
@synthesize fbLogout = _fbLogout;
@synthesize btnWhySignIn = _btnWhySignIn;
@synthesize delegate = _delegate;
@synthesize faqVC = _faqVC;
@synthesize lblSignInType = _lblSignInType;
@synthesize lblSignInName = _lblSignInName;


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
    [self initVersionSection];
    [self initCountDownSection];
    [self initNameSection];
}

- (void) viewDidAppear:(BOOL)animated
{
    BOOL isAnonymous = [[UserData singleton] isAnonymousUser];
    self.btnFBSignIn.hidden = !isAnonymous;
    self.fbLogout.hidden = isAnonymous;
}

- (void) initNameSection
{
    UserData * ud = [UserData singleton];
    
    if( [ud isAnonymousUser] )
    {
        self.lblSignInType.text = @"Anonymous";
        self.lblSignInName.text = @"Anonymous";
    } else {
        self.lblSignInType.text = @"Facebook";
        self.lblSignInName.text = ud.userName;
    }
}

- (void) initVersionSection
{
    NSString * versionString = [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	NSString * buildString = [NSString stringWithFormat:@"(%@)",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];    
    self.appVersionString.text = [[versionString stringByAppendingString:@" "] stringByAppendingString:buildString];
}

- (void) initCountDownSection
{
    UserData *ud = [UserData singleton];
    NSNumber  *countDownValue = [[NSNumber alloc] initWithInt:ud.defaultSecondsPriorRecording];    
    self.sldCountdown.value = countDownValue.intValue;
    self.lblCountdownValue.text = [[NSString alloc] initWithFormat:@"%d sec", countDownValue.intValue];                                    
    [self.lblCountdownValue sizeToFit];    
}


- (void)viewDidUnload
{
    [self setSldCountdown:nil];
    [self setLblCountdownValue:nil];
    [self setAppVersionString:nil];
    
    [self setBtnFBSignIn:nil];
    [self setLblSignInType:nil];
    [self setLblSignInName:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)btnSignInPressed:(id)sender 
{
    [self.delegate userRequestedFBSignIn];
    [FlurryAnalytics logEvent:@"OPT:FB Signin"];
    
}


- (IBAction)btnLogoutPressed:(id)sender {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Sign out from Facebook?\nAll local data will be deleted."
                                                             delegate:self
                                                    cancelButtonTitle:@"No, do not sign out" 
                                               destructiveButtonTitle:@"Yes, sign out"
                                                    otherButtonTitles:nil];
    
    [actionSheet showInView:self.tabBarController.view];    
}

- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index
{
    if (index != sender.destructiveButtonIndex)
        return;

    [self.delegate userRequestedFBSignout];
    
    [FlurryAnalytics logEvent:@"OPT:FB Signout"];
}

- (IBAction)sliderMoved:(id)sender {
    UserData *ud = [UserData singleton];
    ud.defaultSecondsPriorRecording = (int)self.sldCountdown.value;
    NSNumber * countdownValue = [[NSNumber alloc] initWithInt:(int)self.sldCountdown.value];
    self.lblCountdownValue.text = [NSString stringWithFormat:@"%d sec", countdownValue.intValue];
}



- (IBAction) btnWhySignInPressed:(UIButton *) sender
{
    [self performSegueWithIdentifier:@"launchFAQView" sender:self];
    
    [FlurryAnalytics logEvent:@"OPT:WSI"];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"launchFAQView"]) {
        self.faqVC = segue.destinationViewController;
        self.faqVC.delegate = self;
        return;
    }
    
    NSAssert(0, @"%s:Can't find segue name", __FUNCTION__);
}

- (void) cancelPressed
{
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [FlurryAnalytics logEvent:@"OPT:WSI Cancelled"];
    
    return;
}


- (void) displaySelected
{
    [self initNameSection];
    
    return;
}

- (void) displayUnselected
{
    return;
}
@end
