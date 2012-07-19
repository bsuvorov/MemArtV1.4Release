//
//  DemoActivityWithSignIn.h
//  ContentCreator
//
//  Created by Boris on 5/28/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "ActivityViewController.h"

@protocol DemoActivityFBSignUp <NSObject>

- (void) userRequestedFBLogin;

@end

@interface DemoActivityWithSignIn : ActivityViewController

@property (nonatomic, weak) id <DemoActivityFBSignUp> fbDelegate;

@end
