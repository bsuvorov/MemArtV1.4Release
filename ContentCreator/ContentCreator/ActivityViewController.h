//
//  DiafilmCellOnPhoneViewController.h
//  ContentCreator
//
//  Created by Boris on 5/8/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Album.h"
#import "ActivityViewCell.h"
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>
#import "EGORefreshTableHeaderView.h"
#import "FullscreenViewController.h"

@interface ActivityViewController : UIViewController <AVAudioPlayerDelegate, AVAudioRecorderDelegate, UITableViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
{
    
@private
    AVAudioPlayer       *audioPlayer;
    BOOL                audioPlaying;

    AVAudioRecorder     *recorder;
    
    NSIndexPath         *previousIndexPlaying;
    NSIndexPath         *currentIndexPlaying;
    
    NSIndexPath         *currentlySharingIndex;
    
    NSTimer             *sliderTimer;
    
    ActivityViewCell    *currentlySelectedCell;
    
// These are variables used by the CommentsView screen
    ActivityViewCell    *currentCellWithComments;
    AVAudioPlayer       *acpAudioPlayer;
    
// These are variables used by the AudioCommentsRecorder screen
    NSTimer             *acrvTimer;
    float               elapsedRecordTime;
    NSString *          audioCommentTmpFile;
    AVAudioPlayer       *arcvAudioPlayer;
    
    NSTimer             *notificationTimer;
    
  	EGORefreshTableHeaderView *_refreshHeaderView;
    BOOL                       _reloading;
}

@property (strong, nonatomic) Album * album;
@property (weak, nonatomic) NSIndexPath * previousIndexPlaying;

- (void) displaySelected;
- (void) displayUnselected;


@end
    