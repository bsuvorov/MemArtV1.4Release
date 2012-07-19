//
//  DemoActivityWithSignIn.m
//  ContentCreator
//
//  Created by Boris on 5/28/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "DemoActivityWithSignIn.h"
#import <Parse/Parse.h>
#import "globalDefines.h"
#import "UserData.h"
#import "dlLog.h"

@interface DemoActivityWithSignIn ()  

@end

@implementation DemoActivityWithSignIn

@synthesize fbDelegate = _fbDelegate;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (IBAction)signupWithFBPressed:(id)sender {
    
    dlLogDebug(@"Logging in with FaceBook");    
    [self.fbDelegate userRequestedFBLogin];
}


@end
