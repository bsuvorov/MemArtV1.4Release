//
//  CaptureView.m
//  ContentCreator
//
//  Created by Aashish Patel on 6/22/12.
//  Copyright (c) 2012 Mulishani LLC. All rights reserved.
//

#import "CaptureView.h"

@interface CaptureView ()


@end

@implementation CaptureView

@synthesize takePictureButton = _takePictureButton;
@synthesize photoLibraryButton = _photoLibraryButton;
@synthesize cancelButton = _cancelButton;
@synthesize cameraTypeButton = _cameraTypeButton;
@synthesize flashButton = _flashButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
