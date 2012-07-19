//
//  DiafilmCellOnPhone.m
//  ContentCreator
//
//  Created by Boris on 5/8/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "dlLog.h"
#import "ActivityViewCell.h"
#import "HelperFunctions.h"
#import "Diafilm.h"
#import "QuartzCore/CALayer.h"
#import "dlLog.h"
#import "globalDefines.h"

#define DIAFILMPIC    0
#define USERPIC       1
#define USERNAMELABEL 2
#define TIMELABEL     3
#define RECORDCOMMENT 4
#define VIEWCOMMENT   5

@interface CommentRecordView ()

@end

@implementation CommentRecordView

@synthesize lblProgressText = _lblCRVProgressText;
@synthesize btnStop = _btnStop;
@synthesize btnApprove = _btnApprove;
@synthesize btnCancel = _btnCancel;
@synthesize slider = _slider;

@end

@interface CommentSummaryView ()

@end

@implementation CommentSummaryView

@synthesize scrollView = _scrollView;
@synthesize btnCancel = _btnCancel;
@synthesize btnsACP = _btnsACP;

@end

@interface CommentPlaybackView ()

@end

@implementation CommentPlaybackView

@synthesize lblCommenter = _lblCommenter;
@synthesize lblProgressText = _lblProgressText;
@synthesize sliderACP = _sliderACP;
@synthesize btnPause = _btnPause;
@synthesize btnPrevComment = _btnPrevComment;
@synthesize btnNextComment = _btnNextComment;
@synthesize btnCancel = _btnCancel;
@synthesize ivCommenter = _ivCommenter;

@end


@interface ActivityViewCell()

@end

@implementation ActivityViewCell

@synthesize albumIndex;
@synthesize diafilmThumbFilename;
@synthesize audioFilename;

@synthesize userPic;
@synthesize diafilmPic;
@synthesize speakerPic = _speakerPic;

@synthesize usernameLabel;
@synthesize timeLabel;
@synthesize shareButton;

// @synthesize durationLabel;
@synthesize backgroundLabel;
@synthesize audioSlider;
@synthesize minProgressLabel;
@synthesize maxProgressLabel;

@synthesize btnAddComment;
@synthesize btnViewComments;
@synthesize lblCommentCount;

@synthesize cpv = _cpv;
@synthesize csv = _csv;
@synthesize crv = _crv;


@synthesize lpgr = _lpgr;

@synthesize tableCellViewDelegate = _tableCellViewDelegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
   
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (IBAction)shareButtonClicked:(UIButton *) sender
{
    [self.tableCellViewDelegate tableCellShareButtonClicked:self];  
    
    return;
}

- (IBAction) commentsAddButtonClicked:(UIButton *) sender
{
    
    [self.tableCellViewDelegate tableCellAddCommentButtonClicked:self];
    
    return;
}



- (IBAction) commentsViewButtonClicked:(UIButton *) sender
{
    [self.tableCellViewDelegate tableCellViewCommentButtonClicked:self sender:sender];
    
    return;
}

- (IBAction) commentPlayButtonClicked:(UIButton *) sender
{
    [self.tableCellViewDelegate tableCellPlayCommentButtonClicked:self sender:sender];
    
    return;
}

/*
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if( point.x > 0 && point.x < self.frame.size.width && point.y > 0 && point.y < self.frame.size.height )
    {
        // Check if it's inside the diaFilm's frame
        if( point.x > self.diafilmPic.frame.origin.x && 
           point.x < (self.diafilmPic.frame.origin.x + self.diafilmPic.frame.size.width) && 
           point.y > self.diafilmPic.frame.origin.y &&
           point.y < self.diafilmPic.frame.origin.y + self.diafilmPic.frame.size.height )
        {
            [self.tableCellViewDelegate tableCellDiaFilmThumbPicClicked:self];
        }
        
        
        return YES;
    }
    

    return NO;
}
*/

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [[event allTouches] anyObject];
    CGPoint point = [touch locationInView:touch.view];
    
    if( point.x > self.diafilmPic.frame.origin.x && 
        point.x < (self.diafilmPic.frame.origin.x + self.diafilmPic.frame.size.width) && 
        point.y > self.diafilmPic.frame.origin.y &&
        point.y < (self.diafilmPic.frame.origin.y + self.diafilmPic.frame.size.height) )
    {
        uielement_touchstart = DIAFILMPIC;
        return;
    }
    
    if( point.x > self.userPic.frame.origin.x && 
        point.x < (self.userPic.frame.origin.x + self.userPic.frame.size.width) && 
        point.y > self.userPic.frame.origin.y &&
        point.y < (self.userPic.frame.origin.y + self.userPic.frame.size.height) )
    {
        uielement_touchstart = USERPIC;
        return;
    }    

    if( point.x > self.usernameLabel.frame.origin.x && 
       point.x < (self.usernameLabel.frame.origin.x + self.usernameLabel.frame.size.width) && 
       point.y > self.usernameLabel.frame.origin.y &&
       point.y < (self.usernameLabel.frame.origin.y + self.usernameLabel.frame.size.height) )
    {
        uielement_touchstart = USERNAMELABEL;
        return;
    }
    
    if( point.x > self.timeLabel.frame.origin.x && 
       point.x < (self.timeLabel.frame.origin.x + self.timeLabel.frame.size.width) && 
       point.y > self.timeLabel.frame.origin.y &&
       point.y < (self.timeLabel.frame.origin.y + self.timeLabel.frame.size.height) )
    {
        uielement_touchstart = TIMELABEL;
        return;
    }   
    
    return;

}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [[event allTouches] anyObject];
    CGPoint point = [touch locationInView:touch.view];
  
    if( point.x > self.diafilmPic.frame.origin.x && 
       point.x < (self.diafilmPic.frame.origin.x + self.diafilmPic.frame.size.width) && 
       point.y > self.diafilmPic.frame.origin.y &&
       point.y < (self.diafilmPic.frame.origin.y + self.diafilmPic.frame.size.height) &&
       uielement_touchstart == DIAFILMPIC)
    {        
        [self.tableCellViewDelegate tableCellDiaFilmThumbPicClicked:self];
        return;
    }
    
    if( point.x > self.userPic.frame.origin.x && 
       point.x < (self.userPic.frame.origin.x + self.userPic.frame.size.width) && 
       point.y > self.userPic.frame.origin.y &&
       point.y < (self.userPic.frame.origin.y + self.userPic.frame.size.height) &&
       uielement_touchstart == USERPIC)
    {
        [self.tableCellViewDelegate tableCellUserPicClicked];
        return;
    }    
    
    if( point.x > self.usernameLabel.frame.origin.x && 
       point.x < (self.usernameLabel.frame.origin.x + self.usernameLabel.frame.size.width) && 
       point.y > self.usernameLabel.frame.origin.y &&
       point.y < (self.usernameLabel.frame.origin.y + self.usernameLabel.frame.size.height) &&
       uielement_touchstart == USERNAMELABEL)
    {
        [self.tableCellViewDelegate tableCellUserLabelClicked];
        return;
    }   
    
    if( point.x > self.timeLabel.frame.origin.x && 
       point.x < (self.timeLabel.frame.origin.x + self.timeLabel.frame.size.width) && 
       point.y > self.timeLabel.frame.origin.y &&
       point.y < (self.timeLabel.frame.origin.y + self.timeLabel.frame.size.height) &&
       uielement_touchstart == TIMELABEL)
    {
        [self.tableCellViewDelegate tableCellTimeLabelClicked];
        return;
    }   
    
    return;
}


#pragma mark ACP (Play) Methods
- (void) hideCPVView:(BOOL) hidden
{
    // self.csv.hidden = hidden;
    return;
}

- (int) CPVstate
{
    return CPVstate;
}

- (void) CPVstart
{
    
}

- (void) CPVplay
{
    
}

- (void) CPVstop
{
    
}

- (void) CPVreset
{
    
}

- (void) CPVidle
{
    
}




#pragma mark ACR (Record) Methods

- (void) hideCRVView:(BOOL) hidden
{
    dlLogDebug(@"Show/Hide hideCRVView");
    self.crv.hidden = hidden;
    return;
}

- (void) CRVsliderSet:(float) limit
{
    // FIXME: no longer relevant for limiit
    self.crv.slider.progress = limit;
    self.crv.lblProgressText.text = [NSString stringWithFormat:@"00:00 / 00:%02d", (int) limit];
    return;
}


- (void) CRVstart
{
    dlLogDebug(@"ACR Start");
    
    CRVstate = CRVSTATE_START;

    // [self.crv.btnRecord setHidden:YES];
    [self.crv.btnApprove setHidden:YES];
    [self.crv.btnCancel setHidden:NO];
    [self.crv.btnStop setHidden:YES];
    // [self.btnCRVReplay setHidden:YES];

    [self.crv.slider setHidden:YES];
    [self.crv.lblProgressText setHidden:YES];
    // [self.lblCRVMin setHidden:YES];
    
    // self.crv.slider.maximumValue = (float) MAX_RECORDING_LENGTH_SECONDS;
    // self.crv.slider.minimumValue = 0.0;
    self.crv.lblProgressText.text = [NSString stringWithFormat:@"00:00 / 00:%02d", (int) MAX_RECORDING_LENGTH_SECONDS];
    // self.lblCRVMin.text = @"00:00";
    
    return;
}

- (void) CRVrecord
{
    dlLogDebug(@"ACR Record");
    
    CRVstate = CRVSTATE_RECORD;
    
    // [self.crv.btnRecord setHidden:YES];
    [self.crv.btnApprove setHidden:YES];
    [self.crv.btnCancel setHidden:YES];
    [self.crv.btnStop setHidden:NO];
    // [self.btnCRVReplay setHidden:YES];
    
    [self.crv.slider setHidden:NO];
    [self.crv.lblProgressText setHidden:NO];
    // [self.lblCRVMin setHidden:NO];
    
    // [self.crv.slider setThumbImage:nil forState:UIControlStateNormal];
    
    
}

- (void) CRVrerecord
{
    dlLogDebug(@"ACR Rerecord");

    [self CRVrecord];
    CRVstate = CRVSTATE_RERECORD;
    
    return;
}

- (void) CRVreplay
{
    dlLogDebug(@"ACR Replay");
    
    CRVstate = CRVSTATE_REPLAY;
    
    // [self.crv.btnRecord setHidden:YES];
    [self.crv.btnApprove setHidden:YES];
    [self.crv.btnCancel setHidden:YES];
    [self.crv.btnStop setHidden:NO];
    // [self.btnCRVReplay setHidden:YES];
    
    [self.crv.slider setHidden:NO];
    [self.crv.lblProgressText setHidden:NO];
    // [self.lblCRVMin setHidden:NO];
    
}

- (void) CRVapprove
{
    dlLogDebug(@"ACR Approve");
    
    CRVstate = CRVSTATE_APPROVE;
    
    return;
    
}

- (void) CRVcancel
{
    dlLogDebug(@"ACR Cancel");
    
    CRVstate = CRVSTATE_CANCEL;
    
    return;
}

- (void) CRVstop
{
    // STOP is a transitional state
    // A view should never be stuck in this state
    
    dlLogDebug(@"ACR Stop");
    CRVstate = CRVSTATE_STOP;
    
    return;
  
    
}

- (void) CRVidle
{
    dlLogDebug(@"ACR Idle");
    
    CRVstate = CRVSTATE_IDLE;
    
    // [self.crv.btnRecord setHidden:YES];
    [self.crv.btnApprove setHidden:NO];
    [self.crv.btnCancel setHidden:NO];
    [self.crv.btnStop setHidden:YES];
    // [self.btnCRVReplay setHidden:YES];
    
    [self.crv.slider setHidden:YES];
    [self.crv.lblProgressText setHidden:YES];
    // [self.lblCRVMin setHidden:YES];
    
}

- (void) CRVsliderChanged
{
    dlLogDebug(@"ACR Slider Changed");
    
    CRVstate = CRVSTATE_SLIDERCHANGED;
    
    return;
       
}

- (int) CRVstate
{
    return CRVstate;
}

- (IBAction) handleLongPress:(UILongPressGestureRecognizer *) gestureRecognizer
{
    [self.tableCellViewDelegate tableCellLongPressGesture:self];
    
    return;
}

@end
