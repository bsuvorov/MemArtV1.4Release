//
//  AudioRecorderViewController.m
//  ContentCreator
//
//  Created by Boris on 5/15/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "AudioRecorderViewController.h"
#import "UserData.h"
#import "globalDefines.h"
#import "FlurryAnalytics.h"
#import "dlLog.h"

@interface AudioRecorderViewController ()
@property (strong, nonatomic) UIImage * diafilmImage;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UILabel *lblRecording;
@property (weak, nonatomic) IBOutlet UIButton *btnApproveRecording;
@property (weak, nonatomic) IBOutlet UIButton *btnRejectRecording;
@property (weak, nonatomic) IBOutlet UIButton *btnStartRecording;
@property (weak, nonatomic) IBOutlet UIButton *btnStopRecording;
@property (weak, nonatomic) IBOutlet UIImageView *labelRecordingImage;

@property (weak, nonatomic) IBOutlet UIView *countdownLabel;
@property (weak, nonatomic) IBOutlet UIImageView *ivReRecord;

@property NSTimeInterval lastRecordedLength;

@end

@implementation AudioRecorderViewController
@synthesize imageView        = _imageView;
@synthesize diafilmImage     = _diafilmImage;
@synthesize mainView = _mainView;

@synthesize lblRecording     = _lblRecording;
@synthesize btnStartRecording = _btnStartRecording;
@synthesize btnStopRecording =_btnStopRecording;
@synthesize labelRecordingImage = _labelRecordingImage;
@synthesize btnApproveRecording = _btnApproveRecording;
@synthesize btnRejectRecording = _btnRejectRecording;

@synthesize lastRecordedLength = _lastRecordedLength;

@synthesize audioRecorderDelegate = _audioRecorderDelegate;

@synthesize countdownLabel = _countdownLabel;
@synthesize ivReRecord = _ivReRecord;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    
    }
    return self;
}

- (void) setApprovalHidden:(BOOL) hidden
{
    self.btnApproveRecording.hidden = hidden;
    self.btnRejectRecording.hidden = hidden;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageView.image = self.diafilmImage;
    self.btnStopRecording.hidden = YES;
    self.lblRecording.text = @"Press mic to record";
	// Do any additional setup after loading the view.
    
    self.countdownLabel.layer.cornerRadius = 10; 
   
}

- (void) setImage: (UIImage *) image
{
    self.diafilmImage = image;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                         NSUserDomainMask, YES);
    NSString *appDocumentDirectory = [paths lastObject];
    recordedTmpFile = [appDocumentDirectory stringByAppendingPathComponent:@"tmp.caf"];
    imageTmpFile    = [appDocumentDirectory stringByAppendingPathComponent:@"tmp.jpg"];
    
    /*
    UserData *ud = [UserData singleton];
    
    // Disabling animation for recording
    [self startAnimationWithCountdown:ud.defaultSecondsPriorRecording];
    startRecordingTimer = [NSTimer scheduledTimerWithTimeInterval:ud.defaultSecondsPriorRecording
                                                           target:self
                                                         selector:@selector(prepareForRecording)
                                                         userInfo:nil
                                                          repeats:NO];
    */
    self.ivReRecord.hidden = YES;
    [FlurryAnalytics logEvent:@"AudioRecord"];
}

- (void) startRecording
{
    [self startRecordingAudioForDuration:MAX_RECORDING_LENGTH_SECONDS];
    recorderTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateRecorderLabel) userInfo:nil repeats:YES];
    
}

- (void) prepareForRecording 
{
    self.lblRecording.hidden = NO;
    self.btnStopRecording.hidden = YES;
    
    [self startRecording];
}

- (void) updateRecorderLabel
{
    self.lblRecording.text = [[NSString alloc] initWithFormat:@"recording 00:%02d", (int)recorder.currentTime];;
}

- (void)viewDidUnload
{
    [self setLblRecording:nil];
    [self setBtnStopRecording:nil];
    [self setImageView:nil];
    [self setBtnApproveRecording:nil];
    [self setBtnRejectRecording:nil];
    [self setLabelRecordingImage:nil];
    [self setMainView:nil];
    [self setIvReRecord:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (UILabel *) createLabel:(NSString *) text
{
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:92.0];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.opaque = YES;
    label.alpha = 1.0;

    
    [label sizeToFit];
    label.center = CGPointMake(self.view.frame.size.width/2,self.view.frame.size.height/2);
    self.countdownLabel.center = CGPointMake(self.view.frame.size.width/2,self.view.frame.size.height/2);
    
    [self.view addSubview:label];
    return label;
}

- (void) startAnimationWithCountdown:(int) count
{
    if (count <= 0)
    {
        self.countdownLabel.hidden = YES;
        return;
    }

    self.countdownLabel.hidden = NO;
    NSString * text = [[NSString alloc] initWithFormat:@"%d", count];
    
    UILabel * label = [self createLabel:text];
    CGAffineTransform transform = label.transform;
    if (CGAffineTransformIsIdentity(transform)) {
        UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseInOut;
        [UIView animateWithDuration:1 delay:0 options:options animations:^{
            label.transform = CGAffineTransformScale(transform, 0.1, 0.1);
        } completion:^(BOOL finished) {
            if (finished) {
                [label removeFromSuperview];
                [self startAnimationWithCountdown: count-1];
            }
        }];            
    }
}


- (void) startRecordingAudioForDuration: (NSTimeInterval) recordDuration
{
    NSError *error;
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error: &error];
    [audioSession setActive:YES error: &error];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:24000.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    NSURL * whereToRecord = [[NSURL alloc] initFileURLWithPath:recordedTmpFile] ;
    
    recorder = [[AVAudioRecorder alloc] initWithURL:whereToRecord settings:recordSetting error:&error];
    if (error)
        dlLogCrit(@"Recorder failed to initialize\n");
    
    
    recorder.delegate = self;
    
    [recorder prepareToRecord];
    if (error)
        dlLogCrit(@"Recorder failed to prepare\n");
    
    
    [recorder recordForDuration:recordDuration];
    
    if (error)
        dlLogCrit(@"Recorder failed to record\n");
    
}

- (void) composeDiafilm:(int) privacyValue
{
    CGSize size = CGSizeMake(MAX_IMAGE_WIDTH, MAX_IMAGE_HEIGHT);
    
    UIImage * destImg = [HelperFunctions scaleImage:self.imageView.image FitInDestSize:size];
    NSData* data = UIImageJPEGRepresentation(destImg, 0.6);
    [data writeToFile:imageTmpFile atomically:YES];

    UserData * ud = [UserData singleton];
    
    [ud.userAlbum addDiafilmToAlbumWith:imageTmpFile AudioFile:recordedTmpFile Permissions:privacyValue];
}

// returns YES, when audio record considered to be valid for diafilm
- (void) stopRecordingAudio
{
    NSError *error;        
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error: &error];
    [audioSession setActive:YES error: &error];
    
    self.lastRecordedLength = recorder.currentTime;
    
    [recorder stop];
    
    if (error)
        dlLogWarn(@"Recorder failed to stop\n");
    
    [audioSession setCategory:AVAudioSessionCategoryPlayback error: &error];
    [audioSession setActive:YES error: &error];
    
    // Logging the length of an audio session
    NSString * recordLength = [NSString stringWithFormat:@"%d", (int) self.lastRecordedLength];
    
    NSDictionary * paramters = [NSDictionary dictionaryWithObjectsAndKeys:recordLength, @"length", nil];
    [FlurryAnalytics logEvent:@"Audio Length" withParameters:paramters];
}

- (void) audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    dlLogCrit(@"Error on decode\n");
}

- (IBAction) startRecording:(id)sender
{
    if( audioPlayer )
    {
        [audioPlayer stop];
        audioPlayer = nil;
    }
    
    self.btnStopRecording.hidden = NO;
    self.btnStartRecording.hidden = YES;
    
    [self startRecording];
}

- (IBAction)stopRecording:(id)sender {
    [self stopRecordingAudio];
}

- (void) compose:(int) permissions
{
    [self composeDiafilm:permissions];
    [self.audioRecorderDelegate isAudioAccepted:YES];
    
    
    [FlurryAnalytics logEvent:@"Audio Approved"];
    
    NSString * userType;
    NSString * dfPrivacyOptions;
    
    UserData * ud = [UserData singleton];
    if( [ud isAnonymousUser] )
    {
        userType = @"Anonymous";
    } else {
        userType = @"FB User";
    }
    
    switch (permissions)
    {
        case DF_PRIVACY_PUBLIC:
            dfPrivacyOptions = @"Public";
            break;
            
        case DF_PRIVACY_PRIVATE:
            dfPrivacyOptions = @"Private";
            break;
            
        case DF_PRIVACY_FB:
            dfPrivacyOptions = @"Friends";
            break;
            
        case DF_PRIVACY_PUBLIC_APPROVED:
            dfPrivacyOptions = @"Public and curated";
            break;
            
        default:
            dfPrivacyOptions = @"Uh.. unknown";
            break;
    }
    NSDictionary * eventDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:userType, @"User Type",
                                      dfPrivacyOptions, @"Privacy Option", nil];
    
    
    [FlurryAnalytics logEvent:@"Diafilm Approved" withParameters:eventDictionary];
}

- (IBAction) btnApprovedTouched:(id)sender 
{
    [audioPlayer stop];

    UserData * ud = [UserData singleton];
    
    if( ![ud isAnonymousUser] )
    {
        UIAlertView * privacyAlert = [[UIAlertView alloc] initWithTitle:@"Distribution Options" 
                                                                message:@"Select privacy:" 
                                                               delegate:self 
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Private", @"Friends", @"Public", nil];

        [privacyAlert show];
    } else {
        [self compose:DF_PRIVACY_PRIVATE];
    }

}

- (void) alertView:(UIAlertView *) alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    int privacyValue;
    
    switch (buttonIndex) 
    {
        case 0:
            privacyValue = DF_PRIVACY_PRIVATE;
            break;
            
        case 1:
            privacyValue = DF_PRIVACY_FB;
            break;
            
        case 2:
            privacyValue = DF_PRIVACY_PUBLIC;
            break;
            
        default:
            privacyValue = DF_PRIVACY_PRIVATE;
            break;
    }
    
    [self compose:privacyValue];
}

- (IBAction)btnRejectTouched:(id)sender {
    [audioPlayer stop];
    [self.audioRecorderDelegate isAudioAccepted:NO];
    
    // Log when a user rejects creation
    [FlurryAnalytics logEvent:@"Audio Rejected"];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder
                           successfully:(BOOL)flag
{
    dlLogDebug(@"Hitting %s", __FUNCTION__);
    [recorderTimer invalidate];

    self.btnStopRecording.hidden = YES;
    // self.lblRecording.hidden = YES;
    // self.labelRecordingImage.hidden = YES;

    [self playbackTmpFile];

    [self setApprovalHidden:NO];
    self.btnStartRecording.hidden = NO;


}

- (void) playbackTmpFile
{
    NSError *error;
    
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error: &error];
    
    if (error)
        dlLogWarn(@"Failed to set audio session category");
    
    [audioSession setActive:YES error: &error];
    
    if (error)
        dlLogWarn(@"Failed to set audio session as active");
    
    NSURL *audioFile = [[NSURL alloc] initWithString:recordedTmpFile];
    
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFile error:&error];
    
    // CYA (cover your ass), if audio is very short for some reason, just move on to next slide
    if (audioPlayer.duration < AUDIO_RECORDING_LENGTH_CONSIDERED_VALID)
        return;
    
    [audioPlayer prepareToPlay];
    if (error)
        dlLogCrit(@"Failed to prepare for playback\n");    
    
    
    // FIXME: This never gets displayed since we remove the top banner
    self.lblRecording.text = (NSString *) @"Review";
    
    [audioPlayer play];
    if (error)
        dlLogWarn(@"Failed to start playing\n");
    
}

@end
