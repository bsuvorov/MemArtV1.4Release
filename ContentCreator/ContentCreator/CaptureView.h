//
//  CaptureView.h
//  ContentCreator
//
//  Created by Aashish Patel on 6/22/12.
//  Copyright (c) 2012 Mulishani LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CaptureView : UIView


@property (nonatomic, strong) IBOutlet UIButton        *takePictureButton;
@property (nonatomic, strong) IBOutlet UIButton        *photoLibraryButton;
@property (nonatomic, strong) IBOutlet UIButton        *cancelButton;

@property (nonatomic, strong) IBOutlet UIButton        *cameraTypeButton;
@property (nonatomic, strong) IBOutlet UIButton        *flashButton;

@end
