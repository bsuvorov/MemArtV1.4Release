//
//  OptionViewController.h
//  ContentCreator
//
//  Created by Aashish Patel on 5/14/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OptionsViewProtocol <NSObject>
- (void) userRequestedFBSignout;
- (void) userRequestedFBSignIn;
@end


@interface OptionViewController : UIViewController
{
    UIButton *          fbLogout;
}

@property (nonatomic, weak) id <OptionsViewProtocol> delegate;

- (void) displaySelected;
- (void) displayUnselected;


@end
