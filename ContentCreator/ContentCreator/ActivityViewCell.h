//
//  DiafilmCellOnPhone.h
//  ContentCreator
//
//  Created by Boris on 5/8/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentRecordView : UIView
{
    
}

// Diafilm: <record comment> bottom bar related information
// Audio Comment Record (ACR)
@property (nonatomic, weak) IBOutlet UILabel           *lblProgressText;
@property (nonatomic, weak) IBOutlet UIButton          *btnStop;
@property (nonatomic, weak) IBOutlet UIButton          *btnApprove;
@property (nonatomic, weak) IBOutlet UIButton          *btnCancel;
@property (nonatomic, weak) IBOutlet UIProgressView    *slider;

// @property (nonatomic, weak) IBOutlet UIButton    *btnCRVRecord;
// @property (nonatomic, weak) IBOutlet UIButton    *btnCRVReplay;

@end

@interface CommentSummaryView : UIView
{
    
}

// Diafilm: <comments> bottom bar related information
// Audio Comment Playback -> comments for a diafilm
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIButton     *btnCancel;
@property (nonatomic, weak) NSArray               *btnsACP; // Array of UIButtons for comments; dynamic


@end

@interface CommentPlaybackView : UIView
{
    
    
}

@property (nonatomic, weak) IBOutlet UILabel         *lblCommenter;
@property (nonatomic, weak) IBOutlet UILabel         *lblProgressText;
@property (nonatomic, weak) IBOutlet UIProgressView  *sliderACP;
@property (nonatomic, weak) IBOutlet UIButton        *btnPause;
@property (nonatomic, weak) IBOutlet UIButton        *btnPrevComment;
@property (nonatomic, weak) IBOutlet UIButton        *btnNextComment;
@property (nonatomic, weak) IBOutlet UIButton        *btnCancel;
@property (nonatomic, weak) IBOutlet UIImageView     *ivCommenter;


@end

@protocol tableCellViewProtocols;

#define CRVSTATE_START    0
#define CRVSTATE_RECORD   1
#define CRVSTATE_RERECORD 2
#define CRVSTATE_REPLAY   3
#define CRVSTATE_APPROVE  4
#define CRVSTATE_CANCEL   5
#define CRVSTATE_STOP     6
#define CRVSTATE_IDLE     7
#define CRVSTATE_SLIDERCHANGED 8

@interface ActivityViewCell : UITableViewCell
{
    int uielement_touchstart;
    int CRVstate;
    int CPVstate;
    
}

@property (nonatomic) int albumIndex;
@property (nonatomic, weak) NSString * diafilmThumbFilename;
@property (nonatomic, weak) NSString * audioFilename;

// Diafilm: top bar information
@property (nonatomic, weak) IBOutlet UIImageView *userPic;
@property (nonatomic, weak) IBOutlet UIImageView *diafilmPic;
@property (nonatomic, weak) IBOutlet UIImageView *speakerPic;

@property (nonatomic, weak) IBOutlet UILabel     *usernameLabel;
@property (nonatomic, weak) IBOutlet UILabel     *timeLabel;
@property (nonatomic, weak) IBOutlet UIButton    *shareButton;

// Diafilm related elements
// @property (nonatomic, weak) IBOutlet UILabel        *durationLabel;
@property (nonatomic, weak) IBOutlet UILabel     *backgroundLabel;
@property (nonatomic, weak) IBOutlet UISlider    *audioSlider;
@property (nonatomic, weak) IBOutlet UILabel     *minProgressLabel;
@property (nonatomic, weak) IBOutlet UILabel     *maxProgressLabel;

@property (nonatomic, weak) IBOutlet UIButton    *btnAddComment;
@property (nonatomic, weak) IBOutlet UIButton    *btnViewComments;
@property (nonatomic, weak) IBOutlet UILabel     *lblCommentCount;

@property (nonatomic, weak) IBOutlet CommentPlaybackView   *cpv;
@property (nonatomic, weak) IBOutlet CommentSummaryView    *csv;
@property (nonatomic, weak) IBOutlet CommentRecordView     *crv;

@property (nonatomic, weak) id <tableCellViewProtocols> tableCellViewDelegate;

@property (weak, nonatomic) IBOutlet UILongPressGestureRecognizer * lpgr;

- (void) hideCPVView:(BOOL) hidden;
- (int)  CPVstate;
- (void) CPVstart;
- (void) CPVplay;
- (void) CPVstop;
- (void) CPVreset;
- (void) CPVidle;

- (void) hideCRVView:(BOOL) hidden;
- (void) CRVstart;
- (void) CRVrecord;
- (void) CRVrerecord;
- (void) CRVreplay;
- (void) CRVapprove;
- (void) CRVcancel;
- (void) CRVstop;
- (void) CRVidle;
- (void) CRVsliderChanged;
- (int)  CRVstate;
- (void) CRVsliderSet:(float) limit;

@end

@protocol tableCellViewProtocols
- (void) tableCellDiaFilmThumbPicClicked:(ActivityViewCell *) cell;
- (void) tableCellUserPicClicked;
- (void) tableCellUserLabelClicked;
- (void) tableCellTimeLabelClicked;
- (void) tableCellShareButtonClicked:(ActivityViewCell *) cell;
- (void) tableCellAddCommentButtonClicked:(ActivityViewCell *) cell;
- (void) tableCellViewCommentButtonClicked:(ActivityViewCell *) cell sender:(UIButton *) sender;
- (void) tableCellPlayCommentButtonClicked:self sender:(UIButton *) sender;
- (void) tableCellLongPressGesture:(ActivityViewCell *) cell;
@end
