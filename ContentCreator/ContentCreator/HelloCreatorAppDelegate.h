//
//  HelloCreatorAppDelegate.h
//  ContentCreator
//
//  Created by Boris on 3/15/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iPhoneTabBarViewController.h"


@interface HelloCreatorAppDelegate : UIResponder <UIApplicationDelegate>
{
    UIWindow                   *window;
    iPhoneTabBarViewController *rootViewController;
    
}
@property (strong, nonatomic) UIWindow                   *window;
@property (strong, nonatomic) iPhoneTabBarViewController *rootViewController;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@end
