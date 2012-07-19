//
//  CaptureViewController.m
//  ContentCreator
//
//  Created by Aashish Patel on 5/14/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "CaptureViewController.h"
#import "AudioRecorderViewController.h"
#import "globalDefines.h"
#import "dlLog.h"
#import "FlurryAnalytics.h"

@interface CaptureViewController () <AudioRecorderViewProtocol>
// UI specific properties

@property (nonatomic, weak) AudioRecorderViewController * arvc;

@property (atomic, weak) UIImage * image;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@end

@implementation CaptureViewController

@synthesize image = _image;
@synthesize arvc = _arvc;

@synthesize imagePickerController = _imagePickerController;

@synthesize captureViewDelegate = _captureViewDelegate;

- (void) setTabBarController:(UITabBarController *) thisTabBarController
{
    parentTabBarController = thisTabBarController;
}

- (void) setImagePickerController: (UIImagePickerController *) new
{
    NSLog(@"Setting new value for imagePickerController, current = %@", _imagePickerController);
    _imagePickerController = new;
    NSLog(@"New value for imagePickerController = %@", _imagePickerController);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }

    return self;
}

- (void)viewDidLoad
{
    
    [self initCameraView];
    [self loadCameraView];
    
    [super viewDidLoad];
    
    displayed = YES;
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [FlurryAnalytics logEvent:@"Camera Loaded"];
    
    return;
}

- (void) loadCameraView
{
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    } else {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.showsCameraControls = NO;

        if( !([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] &&
              [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear] ))
        {
            captureView.cameraTypeButton.hidden = TRUE;
        }
        
        if( !([UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceRear]))
        {
            captureView.flashButton.hidden = TRUE;
        }
        
        switch (self.imagePickerController.cameraFlashMode)
        {
            case UIImagePickerControllerCameraFlashModeOn:
                [captureView.flashButton setImage:[UIImage imageNamed:@"flash_icon_on.png"] forState:UIControlStateNormal];
                break;
            case UIImagePickerControllerCameraFlashModeOff:
                [captureView.flashButton setImage:[UIImage imageNamed:@"flash_icon_off.png"] forState:UIControlStateNormal];
                break;
            case UIImagePickerControllerCameraFlashModeAuto:
                [captureView.flashButton setImage:[UIImage imageNamed:@"flash_icon_auto.png"] forState:UIControlStateNormal];
                break;
            default:
                break;
        }
        
    }
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
    // [self presentModalViewController:self.imagePickerController animated:YES];
}

- (void) initCameraView
{
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
        
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.showsCameraControls = NO;
        self.imagePickerController.cameraViewTransform = CGAffineTransformMakeScale(1.10, 1.10);

        NSArray * captureViewNib = [[NSBundle mainBundle] loadNibNamed:@"CaptureView" owner:self options:nil];
        CaptureView * camOverlayView = [captureViewNib objectAtIndex:0];
        self.imagePickerController.cameraOverlayView = camOverlayView;
        captureView = camOverlayView;

        [self.view addSubview:self.imagePickerController.view];

    } else {
        [self.view addSubview:self.imagePickerController.view];
    }
}

- (void)viewDidUnload
{
    NSLog(@"CaptureViewController %s got called!!!!", __FUNCTION__);
    [super viewDidUnload];
    self.imagePickerController = nil;
    displayed = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) displaySelected
{
    if (displayed != YES )
    {
        [self loadCameraView];
        displayed = YES;
    }

    return;
}

- (void) displayUnselected
{
    displayed = NO;    
    return;
}

#pragma mark -
#pragma mark Photo Library Actions
- (IBAction)photoLibraryAction:(id)sender
{    
    if (self.imagePickerController == 0)
    {
        dlLogCrit(@"ImagePickerController equals to 0 in %s", __FUNCTION__);
        [self viewDidLoad];
    }
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self.imagePickerController setWantsFullScreenLayout:NO];
    
    
    [FlurryAnalytics logEvent:@"CV:Library"];
    return;
}

- (IBAction) switchCameraDevice:(id)sender
{
    if(self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront ) {
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;      
        if( !([UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceRear]))
        {
            captureView.flashButton.hidden = TRUE;
        } else {
            captureView.flashButton.hidden = FALSE;
        }
    } else {
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        if( !([UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceFront]))
        {
            captureView.flashButton.hidden = TRUE;
        } else {
            captureView.flashButton.hidden = FALSE;
        }
    }
    return;
}

- (IBAction) switchFlashMode:(id)sender
{
    if (self.imagePickerController.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
        self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
        [captureView.flashButton setImage:[UIImage imageNamed:@"flash_icon_auto.png"] forState:UIControlStateNormal];
    } else if(self.imagePickerController.cameraFlashMode == UIImagePickerControllerCameraFlashModeAuto) {
        self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        [captureView.flashButton setImage:[UIImage imageNamed:@"flash_icon_on.png"] forState:UIControlStateNormal];
    } else if(self.imagePickerController.cameraFlashMode == UIImagePickerControllerCameraFlashModeOn) {
        self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        [captureView.flashButton setImage:[UIImage imageNamed:@"flash_icon_off.png"] forState:UIControlStateNormal];
    }
}

#pragma mark -
#pragma mark Camera Actions
- (IBAction)takePhoto:(id)sender
{
    if (self.imagePickerController == 0)
    {
        dlLogCrit(@"ImagePickerController equals to 0 in %s", __FUNCTION__);
        [self viewDidLoad];
    }
    [self.imagePickerController takePicture];
    [FlurryAnalytics logEvent:@"CV:Picture"];
}

- (IBAction)cancelPhoto:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.captureViewDelegate captureViewDone];
    [FlurryAnalytics logEvent:@"CV:Cancel"];
    return;    
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

// this get called when an image has been chosen from the library or taken from the camera
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        dispatch_queue_t downloadQueue = dispatch_queue_create("image picker saver", NULL);
        dispatch_async(downloadQueue, ^{
            UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil);
        });
    }
    
    [FlurryAnalytics logEvent:@"CV:Pic Selected"];
    
    [self dismissViewControllerAnimated:(NO) completion:^{
        [self performSegueWithIdentifier:@"AudioRecord" sender:self];
    }];
    
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AudioRecord"]) {
        self.arvc = segue.destinationViewController;
        self.arvc.audioRecorderDelegate = self;
        [segue.destinationViewController setImage:self.image];
        return;
    }
    
    NSAssert(0, @"%s:Can't find segue name", __FUNCTION__);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    // if the device doesn't have a camera and the user presses cancel, go back
    // to the activity view
    
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [self dismissViewControllerAnimated:NO completion:nil];       
        [self.captureViewDelegate captureViewDone];

    } else {
        // else go back to the camera view
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    
}


- (void) isAudioAccepted:(BOOL) AudioAcceptance
{
    // Audio was accepted - dismiss that view
    // and then do whatever the delegate wants to do
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.captureViewDelegate captureViewDone];
    
}

- (void) dealloc
{
    NSLog(@"%s of %@", __FUNCTION__, self);
}


@end
