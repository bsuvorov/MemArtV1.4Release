//
//  iPhoneTabBarViewController.h
//  ContentCreator
//
//  Created by Boris on 5/7/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TabBarProtocol <NSObject>
- (void) performFBSignIn;
- (void) performFBSignout;
@end

@interface iPhoneTabBarViewController : UITabBarController <UITabBarControllerDelegate>
{
    int previousSelectedIndex;
    
}

@property (nonatomic, weak) id <TabBarProtocol> signupDelegate;
- (void) tabBarController: (UITabBarController *) tabBarController didSelectViewController: (UIViewController *) viewController;
- (void) selectDisplay:(int) viewControllerIndex prev:(int) previousSelectedIndex;
- (void) unselectDisplay:(int) viewControllerIndex;


@end
