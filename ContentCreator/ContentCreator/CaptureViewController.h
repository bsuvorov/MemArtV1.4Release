//
//  CaptureViewController.h
//  ContentCreator
//
//  Created by Aashish Patel on 5/14/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
// #import "OverlayViewController.h"
#import "CaptureView.h"

@protocol captureViewProtocols
- (void) captureViewDone;
@end

@interface CaptureViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioPlayerDelegate>
{
@private
    BOOL                    displayed;
    CaptureView             *captureView;
    
    UITabBarController      *parentTabBarController;
}

@property (nonatomic, weak) id <captureViewProtocols> captureViewDelegate;

- (void) displaySelected;
- (void) displayUnselected;
- (void) setTabBarController:(UITabBarController *) thisTabBarController;

@end

