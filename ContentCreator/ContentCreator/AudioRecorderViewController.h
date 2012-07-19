//
//  AudioRecorderViewController.h
//  ContentCreator
//
//  Created by Boris on 5/15/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol AudioRecorderViewProtocol
- (void) isAudioAccepted:(BOOL) AudioAcceptance;
@end

@interface AudioRecorderViewController : UIViewController <AVAudioRecorderDelegate>
{
@private
    AVAudioRecorder *recorder;
    AVAudioPlayer * audioPlayer;
    NSTimer  *recorderTimer;
    NSTimer  *startRecordingTimer;
    NSString *recordedTmpFile;
    NSString *imageTmpFile;
}

@property (nonatomic, weak) id <AudioRecorderViewProtocol> audioRecorderDelegate;

- (void) setImage: (UIImage *) image;

@end
