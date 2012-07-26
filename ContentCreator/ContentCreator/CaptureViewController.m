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
#import "HelloCreatorAppDelegate.h"

@interface CaptureViewController () <AudioRecorderViewProtocol>
// UI specific properties

@property (nonatomic, weak) AudioRecorderViewController * arvc;

@property (atomic, weak) UIImage * image;


@end

@implementation CaptureViewController

@synthesize image = _image;
@synthesize arvc = _arvc;

@synthesize captureViewDelegate = _captureViewDelegate;

- (void) setTabBarController:(UITabBarController *) thisTabBarController
{
    parentTabBarController = thisTabBarController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
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
    HelloCreatorAppDelegate * appDelegate = (HelloCreatorAppDelegate *)([UIApplication sharedApplication].delegate);
    
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        appDelegate.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    } else {
        appDelegate.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        appDelegate.imagePickerController.showsCameraControls = NO;
        
        if( !([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] &&
              [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear] ))
        {
            captureView.cameraTypeButton.hidden = TRUE;
        }
        
        if( !([UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceRear]))
        {
            captureView.flashButton.hidden = TRUE;
        }
        
        switch (appDelegate.imagePickerController.cameraFlashMode)
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
    
    // don't show captureView till imagePickerController is not yet fully shown.
    [self presentViewController:appDelegate.imagePickerController animated:NO completion:^(void)
     {
         captureView.hidden = NO;
     }];
    
    // [self presentModalViewController:self.imagePickerController animated:YES];
}

- (void) deallocPickerAndCaptureView
{
    HelloCreatorAppDelegate * appDelegate = (HelloCreatorAppDelegate *)([UIApplication sharedApplication].delegate);
    appDelegate.imagePickerController = nil;
    captureView = nil;
}

- (void) initCameraView
{
    HelloCreatorAppDelegate * appDelegate = (HelloCreatorAppDelegate *)([UIApplication sharedApplication].delegate);
    appDelegate.imagePickerController = [[UIImagePickerController alloc] init];
    appDelegate.imagePickerController.delegate = self;
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        appDelegate.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        appDelegate.imagePickerController.showsCameraControls = NO;
        appDelegate.imagePickerController.cameraViewTransform = CGAffineTransformMakeScale(1.10, 1.10);
        
        NSArray * captureViewNib = [[NSBundle mainBundle] loadNibNamed:@"CaptureView" owner:self options:nil];
        CaptureView * camOverlayView = [captureViewNib objectAtIndex:0];
        camOverlayView.hidden = YES;
        appDelegate.imagePickerController.cameraOverlayView = camOverlayView;
        captureView = camOverlayView;
        [self.view addSubview:appDelegate.imagePickerController.view];
        
    } else {
        [self.view addSubview:appDelegate.imagePickerController.view];
    }
}

- (void) viewDidDisappear:(BOOL)animated
{
    NSLog(@"%@ dissapeared", self);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self deallocPickerAndCaptureView];
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
        displayed = YES;
    }
    
    HelloCreatorAppDelegate * appDelegate = (HelloCreatorAppDelegate *)([UIApplication sharedApplication].delegate);
    
    NSAssert(!appDelegate.imagePickerController, @"picker has to be nil at this point, we alloc/dealloc it everytime we start using it and finish using it");
    
    
    [self initCameraView];
    [self loadCameraView];    
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
    HelloCreatorAppDelegate * appDelegate = (HelloCreatorAppDelegate *)([UIApplication sharedApplication].delegate);
    if (appDelegate.imagePickerController == 0)
    {
        dlLogCrit(@"ImagePickerController equals to 0 in %s", __FUNCTION__);
        
    }
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    appDelegate.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [appDelegate.imagePickerController setWantsFullScreenLayout:NO];
    
    
    [FlurryAnalytics logEvent:@"CV:Library"];
    return;
}

- (IBAction) switchCameraDevice:(id)sender
{
    HelloCreatorAppDelegate * appDelegate = (HelloCreatorAppDelegate *)([UIApplication sharedApplication].delegate);
    
    if(appDelegate.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront ) {
        appDelegate.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;      
        if( !([UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceRear]))
        {
            captureView.flashButton.hidden = TRUE;
        } else {
            captureView.flashButton.hidden = FALSE;
        }
    } else {
        appDelegate.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
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
    HelloCreatorAppDelegate * appDelegate = (HelloCreatorAppDelegate *)([UIApplication sharedApplication].delegate);
    
    if (appDelegate.imagePickerController.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
        appDelegate.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
        [captureView.flashButton setImage:[UIImage imageNamed:@"flash_icon_auto.png"] forState:UIControlStateNormal];
    } else if(appDelegate.imagePickerController.cameraFlashMode == UIImagePickerControllerCameraFlashModeAuto) {
        appDelegate.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        [captureView.flashButton setImage:[UIImage imageNamed:@"flash_icon_on.png"] forState:UIControlStateNormal];
    } else if(appDelegate.imagePickerController.cameraFlashMode == UIImagePickerControllerCameraFlashModeOn) {
        appDelegate.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        [captureView.flashButton setImage:[UIImage imageNamed:@"flash_icon_off.png"] forState:UIControlStateNormal];
    }
}

#pragma mark -
#pragma mark Camera Actions
- (IBAction)takePhoto:(id)sender
{
    HelloCreatorAppDelegate * appDelegate = (HelloCreatorAppDelegate *)([UIApplication sharedApplication].delegate);
    
    if (appDelegate.imagePickerController == 0)
    {
        dlLogCrit(@"ImagePickerController equals to 0 in %s", __FUNCTION__);
        [self initCameraView];
        [self loadCameraView];
    }
    [appDelegate.imagePickerController takePicture];
    [FlurryAnalytics logEvent:@"CV:Picture"];
}

- (IBAction)cancelPhoto:(id)sender
{
    HelloCreatorAppDelegate * appDelegate = (HelloCreatorAppDelegate *)([UIApplication sharedApplication].delegate);
    
    [appDelegate.imagePickerController dismissViewControllerAnimated:NO
                                                          completion:^(void) 
     {
         [self deallocPickerAndCaptureView];
     }];
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
    
    [picker dismissViewControllerAnimated:(NO) completion:^{
        [self deallocPickerAndCaptureView];
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
        [picker dismissViewControllerAnimated:NO completion:nil]; 
        [self dismissViewControllerAnimated:NO completion:nil];
        [self deallocPickerAndCaptureView];
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
    HelloCreatorAppDelegate * appDelegate = (HelloCreatorAppDelegate *)([UIApplication sharedApplication].delegate);
    
    [appDelegate.imagePickerController dismissViewControllerAnimated:NO completion:^(void) {
        [self deallocPickerAndCaptureView];
    }];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.captureViewDelegate captureViewDone];
    
}

- (void) retakePicture
{
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [self initCameraView];
    [self loadCameraView];
    return;
}

- (void) dealloc
{
    NSLog(@"%s of %@", __FUNCTION__, self);
}


@end
