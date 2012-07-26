//
//  DiafilmCellOnPhoneViewController.m
//  ContentCreator
//
//  Created by Boris on 5/8/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "ActivityViewController.h"
#import "ActivityViewCell.h"
#import "UserData.h"
#import "globalDefines.h"
#import "dlLog.h"
#import "VideoCreator.h"
#import "CustomBadge.h"
#import "FlurryAnalytics.h"
#import "SectionHeaderView.h"
#import "FullscreenViewController.h"


#define DOWNLOADTYPE_NEW 0
#define DOWNLOADTYPE_OLD 1

@interface ActivityViewController () <AlbumEvents, UserDataFriendsIDsDelegate, UserUploadDelegate, tableCellViewProtocols, VideoCreatorProtocols, EGORefreshTableHeaderDelegate, fullscreenProtocols>


@property BOOL firstTimePlayingAudio;

// used to track if new diafilms appeared while user was doing something else
@property int sizeOfAlbumWhenDissapearing;

// used to track if new diafilms downloaded and user should be notified about this
@property int sizeofAlbumLastTimeQueried;

@property (weak, nonatomic) IBOutlet UIButton *bbtnRefresh;
@property (weak, nonatomic) IBOutlet UILabel *lblNewDiafilmsCount;
@property (weak, nonatomic) IBOutlet UILabel *lblTotalDiafilmsWaitingForDowload;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSString * videoOutputPath;

@property (weak, nonatomic) IBOutlet UIView * loadingView;

@property (strong, nonatomic) CustomBadge * downloadedBadge;

@property (weak, nonatomic) IBOutlet UIView * headerView;

@property (weak, nonatomic) IBOutlet UILabel * lblNotification;

@property (weak, nonatomic) IBOutlet UIButton * btnLoadMore;

@property (nonatomic) BOOL requestToLoadMore;

// @property (strong, nonatomic) IBOutlet CommentsView * commentsView;
// @property (strong, nonatomic) IBOutlet AudioCommentRecorder * audioCommentRecorderView;

@property (weak, nonatomic) FullscreenViewController * fullscreenViewController;

@property (weak, nonatomic) NSString * lastSavedDFTokenString;
@property (nonatomic) int downloadType;

@end

@implementation ActivityViewController

#define DEBUG_ACTIVITY 1

@synthesize album = _album;
@synthesize sizeOfAlbumWhenDissapearing = _sizeOfAlbumWhenDissapearing;
@synthesize sizeofAlbumLastTimeQueried = _sizeofAlbumLastTimeQueried;
@synthesize bbtnRefresh = _bbtnRefresh;
@synthesize lblNewDiafilmsCount = _lblNewDiafilmsCount;
@synthesize lblTotalDiafilmsWaitingForDowload = _lblTotalDiafilmsWaitingForDowload;
@synthesize tableView = _tableView;
@synthesize loadingView = _loadingView;
@synthesize downloadedBadge = _downloadedBadge;
// @synthesize commentsView = _commentsView;
// @synthesize audioCommentRecorderView = _audioCommentRecorderView;
@synthesize headerView = _headerView;

@synthesize previousIndexPlaying = _previousIndexPlaying;
@synthesize firstTimePlayingAudio = _firstTimePlayingAudio;
@synthesize lblNotification = _lblNotification;

@synthesize videoOutputPath = _videoOutputPath;

@synthesize fullscreenViewController = _fullscreenViewController;

@synthesize btnLoadMore = _btnLoadMore;

@synthesize requestToLoadMore = _requestToLoadMore;

// Save the last DF and check to see if there are no more DFs
// This is a hack - ideally, the return on download would report there are 0
// from the model than this UI hack.
@synthesize lastSavedDFTokenString = _lastSavedDFTokenString;
@synthesize downloadType;

- (IBAction)refreshButtonClick:(id)sender {
    self.bbtnRefresh.enabled = NO;
    [self downloadAlbumNextXDiafilms:0 WithScroll:NO];
    self.bbtnRefresh.enabled = YES;
    
}

- (IBAction) btnLoadMorePressed:(UIButton *) sender
{
    dlLogDebug(@"Load More Button Pressed");

   
    [self.btnLoadMore setTitle:@"Loading..." forState:UIControlStateNormal];
    [self downloadAlbumNextXDiafilms:DEFAULT_ALBUM_NEXT_FETCH_SIZE WithScroll:YES];

    [FlurryAnalytics logEvent:@"AVC:Load More"];
    
    return;
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // self.navigationBarHidden = TRUE;
        // Custom initialization
    }
    return self;
    
}

- (void) setAlbum:(Album *) album
{
    if (_album != nil)
    {
//        NSLog(@"Attempt to remove observer for album %@ for observer %@", _album, self);
//         [_album removeObserver:self forKeyPath:@"availableShadowDiafilmsCount"];
    }
    
    if (album != nil)
    {
//        NSLog(@"Adding observer to album %@ for observer %@", album, self);
//        [album addObserver:self forKeyPath:@"availableShadowDiafilmsCount" options:NSKeyValueObservingOptionNew context:nil];        
    }
    
    _album = album;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    audioPlaying = FALSE;
    self.firstTimePlayingAudio = TRUE;
        
    self.tableView.delegate = self;
    self.album.delegate = self;
    [self downloadAlbumNextXDiafilms:0 WithScroll:NO];
    
    self.loadingView.layer.masksToBounds = YES;
    self.loadingView.layer.cornerRadius = 10;
    
    [self createDownloadBadge];
    
    if (self.album.currentlyDownloading)
        [self rotateRefreshButton];
    
    /*
    if (_refreshHeaderView == nil) {
		
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		view.delegate = self;
		[self.tableView addSubview:view];
		_refreshHeaderView = view;	
	}
	
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
    */
	
    self.lastSavedDFTokenString = nil;
}

- (void) createDownloadBadge
{
    self.downloadedBadge = [CustomBadge customBadgeWithString:@" "
                                              withStringColor:[UIColor whiteColor] 
                                               withInsetColor:[UIColor redColor] 
                                               withBadgeFrame:YES
                                          withBadgeFrameColor:[UIColor whiteColor] 
                                                    withScale:1.0
                                                  withShining:YES];
    
    self.downloadedBadge.userInteractionEnabled = NO;
    self.downloadedBadge.hidden = YES;
    self.downloadedBadge.frame = CGRectMake( 285.0, 0.0, 30.0, 30.0 );
    [self.headerView addSubview:self.downloadedBadge];
}




- (void) viewDidAppear:(BOOL)animated
{
    if (self.album.currentSize > self.sizeOfAlbumWhenDissapearing)
        [self.tableView reloadData];
    
    if (self.album.currentlyDownloading)
        [self rotateRefreshButton];
}

- (void) viewDidDisappear:(BOOL)animated
{
    self.sizeOfAlbumWhenDissapearing = self.album.currentSize;
    
    if (self.album.currentlyDownloading)
        [self stopRotatingRefreshButton];
    
    [audioPlayer stop];
}

- (void)viewDidUnload
{
    dlLogInfo(@"Unloading Activity View");
    
    [self setBbtnRefresh:nil];
    [self setLblNewDiafilmsCount:nil];
    [self setLblTotalDiafilmsWaitingForDowload:nil];
    [super viewDidUnload];
    self.album.delegate = nil;
    self.album = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

#ifdef LIKE_INSTAGRAM
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    // return 1;
    // Return the number of rows in the section.
    self.sizeofAlbumLastTimeQueried = self.album.currentSize;
    return self.sizeofAlbumLastTimeQueried;
}
#else
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

#endif

#ifdef LIKE_INSTAGRAM
- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:@"SectionHeader"
                                                    owner:self options:nil];
    
    SectionHeaderView * sectionHeaderView;
    
    for (id object in bundle) {
        if ([object isKindOfClass:[SectionHeaderView class]])
            sectionHeaderView = (SectionHeaderView *)object;
    }
    
    Diafilm * df = [self.album getDiafilmAtIndex:section];
    
    sectionHeaderView.lblUsername.text = [df getUsername];
    sectionHeaderView.lblTimetaken.text = [df getImageDate];
    [sectionHeaderView.ivUserpic setImage:[df getUserPic]];
    
    return sectionHeaderView;
}
#endif

#ifdef LIKE_INSTAGRAM
- (float) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 45.0;
}
#endif

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{   
#ifdef LIKE_INSTAGRAM
    return 1;
#else    
    // Return the number of rows in the section.
    dlLogDebug(@"*******************************");
    if (DEBUG_ACTIVITY) dlLogDebug(@"TableView: Size of album is %d", self.album.currentSize);
    dlLogDebug(@"*******************************");
    self.sizeofAlbumLastTimeQueried = self.album.currentSize;
    return self.sizeofAlbumLastTimeQueried;
#endif
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (DEBUG_ACTIVITY) dlLogDebug(@"Showing cell @ row %d", indexPath.row);
    
    
    static NSString *CellIdentifier = @"Cell";
    ActivityViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if( cell == nil )
    {
        NSArray * tableCellViews = [[NSBundle mainBundle] loadNibNamed:@"ActivityViewCell" owner:self options:nil];
        cell = (ActivityViewCell *) [tableCellViews objectAtIndex:0]; 
        [cell addSubview:cell.csv];
        [cell addSubview:cell.crv];
        [cell addSubview:cell.cpv];
    }
    
    cell.csv.hidden = TRUE;
    cell.cpv.hidden = TRUE;
    cell.crv.hidden = TRUE;

    
#ifdef LIKE_INSTAGRAM
    Diafilm * df = [self.album getDiafilmAtIndex:indexPath.section];
#else
    Diafilm * df = [self.album getDiafilmAtIndex:indexPath.row];
#endif
    cell.userPic.image = [df getUserPic];
    
    cell.diafilmPic.image = [df getThumbNail];
    if( [df getThumbNail] == nil )
    {
        cell.diafilmPic.image = [UIImage imageNamed:@"placeholder_loading.png"];
    }
    
    // cell.diafilmPic.image = [UIImage imageWithCGImage:cell.diafilmPic.image.CGImage scale:2 orientation:cell.diafilmPic.image.imageOrientation];
    cell.usernameLabel.text = [df getUsername];
    cell.timeLabel.text = [df getImageDate];
    
    cell.albumIndex = indexPath.row;
    cell.diafilmThumbFilename = [df getThumbNailFileName];
    cell.audioFilename = [df getAudioFilename];
    cell.tableCellViewDelegate = self;

    dlLogDebug(@"user %@", df.owner.name);

    if(audioPlaying && currentIndexPlaying == indexPath)
    {
        [self showSliderSet:cell show:YES];
    } else {
        [self showSliderSet:cell show:NO];
        
    }
    
    cell.lblCommentCount.text = [NSString stringWithFormat:@"%d", [df getCommentCount]];
    
    if( [df getCommentCount] == 0 )
    {
        cell.lblCommentCount.hidden = TRUE;
        cell.btnViewComments.hidden = TRUE;
    }
    
    return cell;
}

- (void) stopAllAudio
{
    if( audioPlayer )
    {
        [audioPlayer stop];
    }
    audioPlayer = nil;
    audioPlaying = FALSE;
    [self showSliderSet:currentlySelectedCell show:NO];
    return;
    
}


- (void) showSliderSet:(ActivityViewCell *) cell show:(BOOL) show
{
    if( show )
    {
        [self drawBorderAroundImage:cell.diafilmPic];
        cell.backgroundLabel.hidden = NO;
        cell.audioSlider.hidden = NO;
        cell.minProgressLabel.hidden = NO;
        cell.maxProgressLabel.hidden = NO;
        cell.speakerPic.hidden = YES;
    } else {
        cell.speakerPic.hidden = NO;
        [self removeBorderAroundImage:cell.diafilmPic];
        cell.backgroundLabel.hidden = YES;
        cell.audioSlider.hidden = YES;
        cell.minProgressLabel.hidden = YES;
        cell.maxProgressLabel.hidden = YES;
        // [sliderTimer invalidate];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Setting height here since Storyboard height doesn't stick
    return 370.0;
}

NSTimeInterval downloadAlbumLastRequest = 0;

- (void) downloadAlbumNextXDiafilms:(int) diafilmsToLoad WithScroll:(BOOL) trueForScroll 
{    
#ifdef LIKE_INSTAGRAM
    NSTimeInterval downloadAlbumCurrentRequest = [[NSDate date] timeIntervalSince1970];
    
    // prevents frequent buffer swap
    if (fabs(downloadAlbumCurrentRequest - downloadAlbumLastRequest) <= 0.1)  {
        if (DEBUG_ACTIVITY) dlLogDebug(@"Ignoring request");
        return;
    }
    
    // Start spinning the icon
    [self rotateRefreshButton];
    
    int prevAlbumSize = self.album.currentSize;
    
    // synchronously swaps buffers and starts async download
    BOOL wasDownloading = self.album.currentlyDownloading;
    
    [self.album startAsyncLoadFromAllSourcesForNextXDiafilms:diafilmsToLoad];
    int albumCurrentSize = self.album.currentSize;

    if ((!wasDownloading && prevAlbumSize == albumCurrentSize) || (prevAlbumSize < 1))
        [self.tableView reloadData];
    else if (prevAlbumSize < albumCurrentSize) {
        int offset = 0;
        // if (trueForScroll)
            offset = prevAlbumSize;
        
        NSMutableArray * rowIndexPathArray = [[NSMutableArray alloc] initWithCapacity:albumCurrentSize-prevAlbumSize];
        for (int i = 0; i < albumCurrentSize - prevAlbumSize; i++)
            [rowIndexPathArray addObject:[NSIndexPath indexPathForRow:0 inSection:offset + i]];
        
        [self.tableView beginUpdates];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(offset, [rowIndexPathArray count])] withRowAnimation:UITableViewRowAnimationBottom];
        [self.tableView insertRowsAtIndexPaths:(NSArray*)rowIndexPathArray withRowAnimation:UITableViewRowAnimationBottom];

        [self.tableView endUpdates];
    }         
    downloadAlbumLastRequest = [[NSDate date] timeIntervalSince1970];
#else
    
    if (self.album.currentlyDownloading)
        return;
    
    if (diafilmsToLoad == 0)
    {
        downloadType = DOWNLOADTYPE_NEW;
    } else {
        downloadType = DOWNLOADTYPE_OLD;
    }
    
    NSTimeInterval downloadAlbumCurrentRequest = [[NSDate date] timeIntervalSince1970];
    
    // prevents frequent buffer swap
    if (fabs(downloadAlbumCurrentRequest - downloadAlbumLastRequest) <= 0.1)  {
        if (DEBUG_ACTIVITY) dlLogDebug(@"Ignoring request");
        return;
    }
    
   
    // Start spinning the icon
    [self rotateRefreshButton];
    [self.album startAsyncLoadFromAllSourcesForNextXDiafilms:diafilmsToLoad];
    self.requestToLoadMore = trueForScroll;
    downloadAlbumLastRequest = [[NSDate date] timeIntervalSince1970];
#endif
}

#pragma mark - Table view delegate
static BOOL _draggingView = NO;
static int startDetecting = 50;


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _draggingView = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    _draggingView = NO;
    // [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView 
{
    
    if (scrollView.contentOffset.y < -startDetecting) 
    {
        _draggingView = NO;
      
        if (DEBUG_ACTIVITY) dlLogDebug(@"Pull Down");
        
        [self downloadAlbumNextXDiafilms:0 WithScroll:NO];
        
    } 

    /*
    else if (scrollView.contentSize.height <= scrollView.frame.size.height && scrollView.contentOffset.y > startDetecting) {
        _draggingView = NO;
        if (DEBUG_ACTIVITY) dlLogDebug(@"Pull Up");
        [self downloadAlbumNextXDiafilms:DEFAULT_ALBUM_NEXT_FETCH_SIZE WithScroll:YES];
    } else if (scrollView.contentSize.height > scrollView.frame.size.height && 
               scrollView.contentSize.height-scrollView.frame.size.height-scrollView.contentOffset.y < -startDetecting) {
        _draggingView = NO;
        [self downloadAlbumNextXDiafilms:DEFAULT_ALBUM_NEXT_FETCH_SIZE WithScroll:YES];
        if (DEBUG_ACTIVITY) dlLogDebug(@"Pull Up");
    }
     */
    
   	// [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}     

- (void) drawBorderAroundImage:(UIImageView *) thisImageView
{
    [thisImageView.layer setBorderColor:[UICOLOR_MEMART CGColor]];
    [thisImageView.layer setBorderWidth:4.0];
    return;
}

- (void) removeBorderAroundImage:(UIImageView *) thisImageView
{
    [thisImageView.layer setBorderWidth:0.0];
    return;
}

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}
*/
 
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (!audioPlaying)
    {
        return;
    }
    
    if( indexPath.row == currentIndexPlaying.row )
    {
        UISlider * tempSlider;
        
        tempSlider = ((ActivityViewCell *) cell).audioSlider;
        

        tempSlider.minimumValue = 0;
        tempSlider.maximumValue = [self getAudioDurationAtIndex:indexPath.row];
        tempSlider.value = audioPlayer.currentTime;
        currentlySelectedCell = (ActivityViewCell *) cell;
        

        [self showSliderSet:((ActivityViewCell *) cell) show:YES];
        [tempSlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
        sliderTimer = nil;
        sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.015 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
        
    }
    return;
}

- (int) getAudioDurationAtIndex:(int) index
{
    NSError *error;
    int duration;
    
    Diafilm *diafilm = [self.album getDiafilmAtIndex:index];    
    NSURL *audioFile = [diafilm getAudioURL];
    
    if (audioFile == nil)
        return -1;
    
    AVAudioPlayer * tmpAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFile error:&error];
    
    duration = (int) tmpAudioPlayer.duration;
    
    // audioPlayer = nil;
    
    return duration;
    
}

- (void)playbackDiafilmAtIndex:(int) index
{
    NSError *error;
    
    Diafilm *diafilm = [self.album getDiafilmAtIndex:index];    
    NSURL *audioFile = [diafilm getAudioURL];
    
    if (audioFile == nil)
        return;
    
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFile error:&error];
    
    audioPlayer.delegate = self;
    // CYA (cover your ass), if audio is very short for some reason, just move on to next slide
    if (audioPlayer.duration < AUDIO_RECORDING_LENGTH_CONSIDERED_VALID)
        return;
    
    // we might want to have a queue of players which are prepared in advance to save some time on loading.
    [audioPlayer prepareToPlay];
    if (error)
        dlLogWarn(@"Failed to prepare for playback\n");
     
    [audioPlayer play];
    audioPlaying = TRUE;
    if (error)
        dlLogCrit(@"Failed to start playing\n");
    
    if (DEBUG_ACTIVITY) dlLogDebug(@"Index = %d", index);
}

- (void) displaySelected
{
    return;
}

- (void) displayUnselected
{
   
    if( audioPlayer )
    {
        [audioPlayer stop];
        audioPlaying = FALSE;
    }
    return;
}

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    // We have two distinct functions playing audio
    // Playback of a diafilm, playback of a comment and playback of a recorded comment
    // we need to check which player we are using and work on it appropriately
    
    if( player == audioPlayer )
    {
        audioPlaying = false;
        [self showSliderSet:currentlySelectedCell show:NO];
        currentlySelectedCell = nil;
        currentIndexPlaying = nil;
        [sliderTimer invalidate];
        
    } else if (player == arcvAudioPlayer ) {
        [currentCellWithComments CRVidle];
        
    } else if (player == acpAudioPlayer) {
        [currentCellWithComments CPVidle];
    }
    
    return;
    
}

- (void)updateSlider {
	// Update the slider about the music time
    currentlySelectedCell.minProgressLabel.text = [NSString stringWithFormat:@"00:%02d", (int) audioPlayer.currentTime];
	currentlySelectedCell.audioSlider.value = audioPlayer.currentTime;
}

- (IBAction)sliderChanged:(UISlider *)sender {
	// Fast skip the music when user scroll the UISlider
	[audioPlayer stop];
	[audioPlayer setCurrentTime:currentlySelectedCell.audioSlider.value];
	[audioPlayer prepareToPlay];
	[audioPlayer play];
}


- (void) requestedDownloadCompleteWithStatus: (BOOL) success
{
    [self stopRotatingRefreshButton];
    
    [self.btnLoadMore setTitle:@"Load More" forState:UIControlStateNormal];
    
    if (!success)
        dlLogCrit(@"Album download failed");
    
    if (self.sizeofAlbumLastTimeQueried == 0 && self.album.currentSize != 0)
        [self.tableView reloadData];
    
    [self.album asyncUploadQueuedFiles];
    
    UserData *ud = [UserData singleton];
    
    
    //    if (ud.friendsDelegate != self && ud.friendsDelegate != nil)
    //        NSAssert(0, @"Someone else is holding friendsDelegate");
    
    // this should be safe, object which ud point will still exist because UserData is singleton
    ud.friendsDelegate = self;
    [ud refreshUserFacebooksFriends];
    
    Diafilm * lastDF = [self.album getDiafilmAtIndex:(self.album.currentSize - 1)];
    if( self.lastSavedDFTokenString == nil )
    {
        self.lastSavedDFTokenString = lastDF.uniqStrToken;
        return;
    }

    if( [[lastDF uniqStrToken] isEqualToString:self.lastSavedDFTokenString] && (downloadType == DOWNLOADTYPE_OLD))
    {
        [self.btnLoadMore setTitle:@"All items Loaded" forState:UIControlStateNormal];
    }
    
    self.lastSavedDFTokenString = lastDF.uniqStrToken;
         
}

- (void) uploadCompleteWithStatus:(BOOL)success
{
    if (success )
    {
        [self setNotificationLabel:@"Content uploaded to server"];
        [FlurryAnalytics logEvent:@"AVC:DF UP OK"];
    } else {
        [self setNotificationLabel:@"Upload failed"];
        [FlurryAnalytics logEvent:@"AVC:DF UP NG"];
    }
    return;
}

- (void) rotateRefreshButton
{

    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1.0 * 1.0 ];
    rotationAnimation.duration = 1.0;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF; 
    // rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    [self.bbtnRefresh.imageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    return;
}


- (void) stopRotatingRefreshButton
{
    [self.bbtnRefresh.imageView.layer removeAllAnimations];

}

- (void) userFriendsRefreshedWithStatus:(BOOL) success FriendListHasChanged: (BOOL) listHasChanged
{
    if (listHasChanged)
    {
        UserData * ud = [UserData singleton];
        self.album.friends = ud.friendsIds;
        [self refreshButtonClick:nil];
    }
}

#pragma mark - VideoCreator Delegates

- (void) videoCreationPercentComplete:(float) percent
{
    dlLogInfo(@"Video %0.2f complete", percent);
}

- (void) videoCreationFailed
{
    dlLogCrit(@"Video creation failed");
    [FlurryAnalytics logEvent:@"Video - Failed"];
    return;
}

- (void) videoCreationDone
{
    dlLogInfo(@"Video Created; Callback called");
    [self.loadingView setHidden:YES];
    [self videoDone:currentlySharingIndex.row]; 
    
}

#pragma mark - UITableViewCell Delegates

- (void) populateComments:(ActivityViewCell *) cell indexPath:(NSIndexPath *) indexPath
{
    
    Diafilm * diaFilm = [self.album getDiafilmAtIndex:indexPath.row];
    
    int commentCount = [diaFilm getCommentCount];
    cell.lblCommentCount.text = [NSString stringWithFormat:@"%d", commentCount];
    
    
    NSArray * existingViews = [cell.csv.scrollView subviews];
    for (int i = 0; i < [existingViews count]; i++ )
    {
        dlLogDebug(@"Subviews exist. Removing");
        UIView * thisView = [existingViews objectAtIndex:i];
        [thisView removeFromSuperview];
    }
    
    for( int i = 0; i < commentCount; i++ )
    {
        UIButton * newUser = [[UIButton alloc] init];
        
        UIImage * userImage = [UIImage imageWithContentsOfFile:[diaFilm getCommentUserPicPathAtIndex:i]];
        newUser.tag = i;
        
        [newUser setImage:userImage forState:UIControlStateNormal];
        [newUser addTarget:cell action:@selector(commentPlayButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [newUser setFrame:CGRectMake((i*35) + 5, 5, 30 , 30)];
        
        [cell.csv.scrollView addSubview:newUser];
    }
    cell.csv.scrollView.contentSize = CGSizeMake((commentCount*30)+5, 30);
    [cell.csv.scrollView setHidden:NO];
    
    return;
}

- (void) tableCellRecordCommentImageClicked:(ActivityViewCell *) cell
{
    dlLogDebug(@"Record Comment Image Clicked");
    return;
}

- (void) tableCellAddCommentButtonClicked:(ActivityViewCell *) cell
{
    currentCellWithComments = cell;
    
    [cell hideCRVView:NO];
    [cell.btnAddComment setHidden:YES];
    [cell CRVstart];
     
    [cell hideCPVView:YES];
    
    cell.crv.frame = CGRectMake( 10.0, 361.0, 300.0, 40.0 );
    cell.crv.hidden = NO;
    cell.csv.hidden = YES;
    cell.cpv.hidden = YES;

    // FIXME: This is kinda hacky to do, since it's actually a method for a
    // button action
    [self acrvBtnRecordPressed:nil];
    
    return;

}

- (void) tableCellViewCommentButtonClicked:(ActivityViewCell *) cell sender:(UIButton *) sender
{
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    
    [self populateComments:cell indexPath:indexPath];
    cell.csv.frame = CGRectMake( 10.0, 361.0, 300.0, 40.0 );
    cell.csv.hidden = NO;
    cell.csv.scrollView.hidden = NO;
    cell.crv.hidden = YES;
    cell.cpv.hidden = YES;
    
    return;
}

- (void) tableCellPlayCommentButtonClicked:(ActivityViewCell *) cell sender:(UIButton *) sender
{
    int tag = sender.tag;
    
    currentCellWithComments = cell;
    
    Diafilm * df = [self getDiaFilmFromCell:cell];
    NSString * commentFile = [df getCommentAudioPathsAtIndex:tag];
    dlLogDebug(@"Comment file: %@", commentFile);

    cell.csv.hidden = YES;
    cell.crv.hidden = YES;
    cell.cpv.frame = CGRectMake( 10.0, 361.0, 300.0, 40.0 );
    cell.cpv.hidden = NO;
    
    [self playAudioFile:commentFile];
    dlLogDebug(@"ACP: play comment: tag %d", tag);
    
    [currentCellWithComments CPVplay];
    
    // FIXME:
    return;
}

- (void) tableCellShareButtonClicked:(ActivityViewCell *) tableViewCell
{
    self.loadingView.hidden = NO;
    [self.view setNeedsDisplay];
    
    
    NSIndexPath * indexPath;
    
    indexPath = [self.tableView indexPathForCell:tableViewCell];
    
    currentlySharingIndex = indexPath;
    
    Diafilm * df = [self.album getDiafilmAtIndex:indexPath.row];
    NSString * diafilmThumbFilename = [df getThumbNailFileName];
    NSString * audioFilename = [df getAudioFilename];
    
    
    NSString * documentsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Make sure that the image thumb pic exists
    BOOL fileExists = [fm fileExistsAtPath:diafilmThumbFilename];
    if( !fileExists )
    {
        dlLogCrit(@"Thumb Pic not found, cannot make vidoe");
        return;
    }
    
    // Make sure the audio file exists
    fileExists = [fm fileExistsAtPath:audioFilename];
    if( !fileExists )
    {
        dlLogCrit(@"Audio file not found, cannot make video");
        return;
    }
    
    // Create the name of the movie file
    // FIXME: Need to check if the directory exists or not
    
    NSString * imageFilenameOnly = [[diafilmThumbFilename lastPathComponent] stringByDeletingPathExtension];
    NSString * tempStr = [documentsPath stringByAppendingPathComponent:PATH_VIDEO];
    NSString * tempStr2 = [tempStr stringByAppendingPathComponent:imageFilenameOnly];
    NSString * outputMovieFilename = [tempStr2 stringByAppendingString:@".m4v"];
    
    // FIXME: This doesn't belong here
    [[NSFileManager defaultManager] createDirectoryAtPath:tempStr withIntermediateDirectories:NO attributes:nil error:nil];
    
    dlLogDebug(@"image: %@", diafilmThumbFilename);
    dlLogDebug(@"audio: %@", audioFilename);
    dlLogDebug(@"output: %@", outputMovieFilename);
    
    
    // FIXME: Maybe we shouldn't delete the file; but it's helpful during debug
    /*
    if ([fm fileExistsAtPath:outputMovieFilename])
    {
        dlLogInfo(@"Video file exists, deleting it!");
        NSError * error;
        [fm removeItemAtPath:outputMovieFilename error:&error];
    }
    */
    
    self.videoOutputPath = [[NSString alloc] initWithString:outputMovieFilename];

    if( ![fm fileExistsAtPath:outputMovieFilename] )
    {
        VideoCreator * videoCreator = [[VideoCreator alloc] init];
        videoCreator.videoCreationDelegate = self;
    
        [videoCreator createVideoWithImageFile:diafilmThumbFilename audioFile:audioFilename outputPath:outputMovieFilename];

        dlLogDebug(@"End of video creation function");
    } else {
        self.loadingView.hidden = YES;
        [self videoDone:indexPath.row];
    }
    
    [FlurryAnalytics logEvent:@"AVC:Share Button"];
    
    return;
}

- (void) tableCellLongPressGesture:(ActivityViewCell *) cell
{
    dlLogDebug(@"Long Press Detected. Launching fullscreen view");
    
    // FIXME: This is where we push the new full screen view
    // [self performSegueWithIdentifier:@"pushFullscreen" sender:self];
    
    [FlurryAnalytics logEvent:@"AVC:Long Gesture"];
    return;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    dlLogDebug(@"%@", NSStringFromClass([[segue destinationViewController] class]));

    if ([segue.identifier isEqualToString:@"pushFullscreen"]) {
        self.fullscreenViewController = segue.destinationViewController;
        self.fullscreenViewController.fullscreenDelegate = self;
        
        // [segue.destinationViewController setImage:self.image];
        return;
    }
    
    NSAssert(0, @"%s:Can't find segue name", __FUNCTION__);
}

- (void) videoDone:(int) row
{
    [self createShareActionSheet:row];
}

- (void) createShareActionSheet:(int) row
{
    // FIXME: this is a hack like no other - yuck
    // Only show post to FB if current user owns the diafilm
    // but the definition of own is weak - when usernames are the same
    
    [FlurryAnalytics logEvent:@"Shared - Clicked"];
    
    Diafilm * df = [self.album getDiafilmAtIndex:row];
    UserData *ud = [UserData singleton];
    
    /*     Use it for CoreData or remove it */
    if( [[ud getUserId] compare:[df getUserId]] == NSOrderedSame )
    {
        
        ud.uploadDelegate = self;
        // Launch action sheet asking user if he wants to email the video
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil 
                                                    otherButtonTitles:@"Save", @"Email", @"Facebook", nil];
        
        
        [actionSheet showInView:[[self view] window]];
        [actionSheet setDelegate:self];
    } else {
        // Launch action sheet asking user if he wants to email the video
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil 
                                                        otherButtonTitles:@"Save", @"Email", nil];
        
        
        
        [actionSheet showInView:[[self view] window]];
        [actionSheet setDelegate:self];
    }
    return;
}

- (void) tableCellDiaFilmThumbPicClicked:(ActivityViewCell *) cell
{
    
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    
    dlLogDebug(@"DiaFilm Clicked");
    if( self.firstTimePlayingAudio == TRUE )
    {
        previousIndexPlaying = indexPath;
        self.firstTimePlayingAudio = FALSE;
    }
    // if user tapped thumbnail which is currently playing audio, stop audio playback
    // DiafilmCellOnPhone *cell = (DiafilmCellOnPhone *) [tableView cellForRowAtIndexPath:indexPath];
    
    if (previousIndexPlaying.row == indexPath.row && audioPlaying == TRUE) {
        if(audioPlayer) {
            [audioPlayer stop];
        }
        [self showSliderSet:cell show:NO];
        audioPlaying = FALSE;
        currentIndexPlaying = nil;
        
    } else {
        ActivityViewCell *oldCell = (ActivityViewCell *) [self.tableView cellForRowAtIndexPath:previousIndexPlaying];
        [self showSliderSet:oldCell show:NO];
        previousIndexPlaying = indexPath;
        
        [self showSliderSet:cell show:YES];
        
        currentIndexPlaying = indexPath;
        currentlySelectedCell = cell;
        // currentlySelectedCell.audioSlider = cell.audioSlider;
        // currentlySelectedCell.audioSlider.maximumValue = [self getAudioDurationAtIndex:indexPath.row];
        currentlySelectedCell.minProgressLabel.text = @"00:00";
        currentlySelectedCell.maxProgressLabel.text = [NSString stringWithFormat:@"00:%02d", [self getAudioDurationAtIndex:indexPath.row]];
        currentlySelectedCell.audioSlider.maximumValue = [self getAudioDurationAtIndex:indexPath.row];
        
        
        // Set the valueChanged target
        [currentlySelectedCell.audioSlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
        sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.015 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
        
        [self playbackDiafilmAtIndex:indexPath.row];
    }
    
    [FlurryAnalytics logEvent:@"AVC:DiaFilm Clicked"];
}

- (void) tableCellUserPicClicked
{
    dlLogDebug(@"User Pic Clicked");
    [FlurryAnalytics logEvent:@"AVC:UserPic"];
}

- (void) tableCellUserLabelClicked
{
    dlLogDebug(@"User Label Clicked");
    [FlurryAnalytics logEvent:@"AVC:UserLabel"];
}

- (void) tableCellTimeLabelClicked
{
    dlLogDebug(@"Time Label Clicked");
    [FlurryAnalytics logEvent:@"AVC:timeLabel"];
}


#pragma mark - UIActionSheetDelegates


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex 
{
    if( buttonIndex == actionSheet.firstOtherButtonIndex + 0 )
    {
        UISaveVideoAtPathToSavedPhotosAlbum(self.videoOutputPath, nil, nil, nil);
    } else if( buttonIndex == actionSheet.firstOtherButtonIndex + 1 ) {
        [FlurryAnalytics logEvent:@"Shared - Email"];
        
        NSData * movieData = [[NSData alloc] initWithContentsOfFile:self.videoOutputPath];
        
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        [picker setSubject:@"My MemArt"];
        [picker addAttachmentData:movieData mimeType:@"video/x-m4v" fileName:@"MemArt.m4v"];
        
        [picker setToRecipients:[NSArray array]];
        [picker setMessageBody:@"With MemArt you can add voice/audio comments to photos and send it to friends and family. \n\nDownload MemArt for the iPhone here: http://itunes.apple.com/us/app/memart/id529925904?ls=1&mt=8" isHTML:NO];
        [picker setMailComposeDelegate:self];
        [self presentModalViewController:picker animated:YES];        
        
        
    } else if ( (buttonIndex == actionSheet.firstOtherButtonIndex + 2) && (actionSheet.numberOfButtons == 4) ) {
        [FlurryAnalytics logEvent:@"Shared - Facebook"];
        dlLogDebug(@"Posting video to facebook");
        UserData *ud = [UserData singleton];
        
        if( [ud isAnonymousUser] )
        {
            UIAlertView * whyFBView = [[UIAlertView alloc] initWithTitle:@"Facebook" 
                                                   message:@"In order to post to Facebook, please sign into Facebook (options screen)" 
                                                  delegate:self 
                                         cancelButtonTitle:@"OK" 
                                         otherButtonTitles:nil];
            [whyFBView show];
        } else {
            [ud postVideoToFacebook:self.videoOutputPath];
        }
    }

}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error 
{
    [self dismissModalViewControllerAnimated:YES];
}


- (void) dealloc
{
    self.album = nil;
    NSLog(@"%s of %@", __FUNCTION__, self);
}

#pragma mark - CommentsView methods
- (void) playAudioFile:(NSString *) thisFile
{
    NSError *error;
    
    [currentCellWithComments CPVplay];
    
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error: &error];
    
    if (error)
        dlLogWarn(@"Failed to set audio session category");
    
    [audioSession setActive:YES error: &error];
    
    if (error)
        dlLogWarn(@"Failed to set audio session as active");
    
    NSURL *audioFile = [[NSURL alloc] initWithString:thisFile];
    
    acpAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFile error:&error];
    acpAudioPlayer.delegate = self;
    
    // CYA (cover your ass), if audio is very short for some reason, just move on to next slide
    if (acpAudioPlayer.duration < AUDIO_RECORDING_LENGTH_CONSIDERED_VALID)
        return;
    
    [acpAudioPlayer prepareToPlay];
    if (error)
        dlLogCrit(@"Failed to prepare for playback\n");    
    
    
    [acpAudioPlayer play];
    if (error)
        dlLogWarn(@"Failed to start playing\n");

        
    return;
}

- (IBAction) commentsViewButtonPressed:(UIButton *) button 
{
 
    Diafilm * thisDiafilm;
    Comment * thisComment;
    
    switch (button.tag) 
    {
        case 1:
            dlLogDebug(@"CommentsView: Button 1 pressed");
            // We know the current call, but we need to get a link to the cell
            thisDiafilm = [self getDiaFilmFromCell:currentCellWithComments];
            
            thisComment = [thisDiafilm.comments.comments objectAtIndex:0]; 
            
            // FIXME: have to write this function
            [self playAudioFile:thisComment.getAudioFile];
            
            // FIXME: I need to rethink how this happens
            [currentCellWithComments CRVreplay];
            
            break;
            
        case 2:
            dlLogDebug(@"CommentsView: Button 2 pressed");
            break;
            
        case 3:
            dlLogDebug(@"CommentsView: Button 3 pressed");
            break;
            
        case 4:
            dlLogDebug(@"CommentsView: Button 4 pressed");
            // We know the current call, but we need to get a link to the cell
           
            thisDiafilm = [self getDiaFilmFromCell:currentCellWithComments];
            thisComment = [thisDiafilm.comments.comments objectAtIndex:0]; 
            
            // FIXME: have to write this function
            [self playAudioFile:thisComment.getAudioFile];
            break;
            
        case 5:
            dlLogDebug(@"CommentsView: Button 5 pressed");
            break;
        case 6:
            dlLogDebug(@"CommentsView: Button 6 pressed");
            break;
        case 7:
            dlLogDebug(@"CommentsView: Button 7 pressed");
            break;
        case 8:
            dlLogDebug(@"CommentsView: Button 8 pressed");
            break;
        case 9:
            dlLogDebug(@"CommentsView: Button 9 pressed");
            break;
        case 10:
            dlLogDebug(@"CommentsView: Button 10 pressed");
            break;
        case 11:
            dlLogDebug(@"CommentsView: Button 11 pressed");
            break;
        case 12:
            dlLogDebug(@"CommentsView: Button 12 pressed");
            break;
            
        default:
            break;
    } 
    
}


#pragma mark - CommentsView Delegates

- (void) saveNewAudioComment
{
    Diafilm * diaFilm = [self getDiaFilmFromCell:currentCellWithComments];
    
    [diaFilm addNewAudioComment:audioCommentTmpFile];
    
    return;
}

#pragma mark - AudioCommentRecorderView (acrv) Methods
- (IBAction) acrvBtnRecordPressed:(id) sender
{
    // This button can be pressed to record an audio comment or to rerecord an audio comment
    // Doesn't rellay matter
    
    switch( [currentCellWithComments CRVstate] )
    {
        case CRVSTATE_START:
            [currentCellWithComments CRVrecord];
            break;
        case CRVSTATE_IDLE:
            [currentCellWithComments CRVrerecord];
            break;
        default:
            dlLogDebug(@"Error in ACRV state table logic");
            break;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                         NSUserDomainMask, YES);
    NSString *appDocumentDirectory = [paths lastObject];
    audioCommentTmpFile = [appDocumentDirectory stringByAppendingPathComponent:@"tmpComment.caf"];

    
    // [self.audioCommentRecorderView sliderReset:MAX_RECORDING_LENGTH_SECONDS];
    elapsedRecordTime = 0.0;
    
    acrvTimer = [NSTimer scheduledTimerWithTimeInterval:0.015
                                                 target:self 
                                               selector:@selector(acrvUpdateTimer) 
                                               userInfo:nil 
                                                repeats:YES];
    
    [self startRecordingAudioForDuration:MAX_RECORDING_LENGTH_SECONDS];
}

- (void) acrvUpdateTimer
{
    elapsedRecordTime += 0.015;
    [currentCellWithComments CRVsliderSet:elapsedRecordTime];
}

- (void) showACPifNeeded
{
    Diafilm * diaFilm = [self getDiaFilmFromCell:currentCellWithComments];
    
    if( [diaFilm getCommentCount] == 0 )
    {
        [currentCellWithComments hideCPVView:YES];
    } else {
        [currentCellWithComments hideCPVView:NO];
    }
}

- (IBAction) acrvBtnApprovePressed:(id) sender
{
    [self saveNewAudioComment];
    [currentCellWithComments CRVapprove];
    [currentCellWithComments hideCRVView:YES];
    [currentCellWithComments.btnAddComment setHidden:NO];
    
    [self showACPifNeeded];
    
    return;
}

- (IBAction) acrvBtnCancelledPressed:(id) sender
{
    [acrvTimer invalidate];
    // [currentCellWithComments CRVsliderReset:MAX_RECORDING_LENGTH_SECONDS];
    [currentCellWithComments CRVcancel];
    [currentCellWithComments hideCRVView:YES];
    [currentCellWithComments.btnAddComment setHidden:NO];
   
    [self showACPifNeeded];
    
    return;
}

- (IBAction) acrvBtnPlaybackPressed:(id) sender
{
    [currentCellWithComments CRVreplay];
    [self playbackTmpFile];
    [currentCellWithComments CRVidle];
}

- (IBAction) acrvBtnStopPressed:(UIButton *) sender
{
    if( [currentCellWithComments CRVstate] == CRVSTATE_RECORD )
    {
        NSError *error;        
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryRecord error: &error];
        [audioSession setActive:YES error: &error];
        
        // self.lastRecordedLength = recorder.currentTime;
        
        [recorder stop];
        
        if (error)
            dlLogWarn(@"Recorder failed to stop\n");
        
        [audioSession setCategory:AVAudioSessionCategoryPlayback error: &error];
        [audioSession setActive:YES error: &error];
        
        [acrvTimer invalidate];
    
        // [self playbackTmpFile];
    } else if ([currentCellWithComments CRVstate] == CRVSTATE_REPLAY ) {
        [arcvAudioPlayer stop];
        [currentCellWithComments CRVidle];
    }

}

- (void) startRecordingAudioForDuration: (NSTimeInterval) recordDuration
{
   
    NSError *error;
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error: &error];
    [audioSession setActive:YES error: &error];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:24000.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    NSURL * whereToRecord = [[NSURL alloc] initFileURLWithPath:audioCommentTmpFile] ;
    
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

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder
                           successfully:(BOOL)flag
{
    dlLogDebug(@"Hitting %s", __FUNCTION__);

    [acrvTimer invalidate];
    [self playbackTmpFile];
    
}



- (void) playbackTmpFile
{
    NSError *error;
    
    [currentCellWithComments CRVreplay];
    
    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error: &error];
    
    if (error)
        dlLogWarn(@"Failed to set audio session category");
    
    [audioSession setActive:YES error: &error];
    
    if (error)
        dlLogWarn(@"Failed to set audio session as active");
    
    NSURL *audioFile = [[NSURL alloc] initWithString:audioCommentTmpFile];
    
    arcvAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFile error:&error];
    arcvAudioPlayer.delegate = self;
    
    // CYA (cover your ass), if audio is very short for some reason, just move on to next slide
    if (arcvAudioPlayer.duration < AUDIO_RECORDING_LENGTH_CONSIDERED_VALID)
        return;
    
    [arcvAudioPlayer prepareToPlay];
    if (error)
        dlLogCrit(@"Failed to prepare for playback\n");    
    
   
    [arcvAudioPlayer play];
    if (error)
        dlLogWarn(@"Failed to start playing\n");


}

- (Diafilm *) getDiaFilmFromCell:(ActivityViewCell *) cell
{
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    
    Diafilm * thisDiaFilm = [self.album getDiafilmAtIndex:indexPath.row];
    
    return( thisDiaFilm );
}

#pragma mark -
#pragma mark UserData Delegates
- (void) notificationTimer
{
    self.lblNotification.hidden = YES;
}

- (void) setNotificationLabel:(NSString *) text
{
    notificationTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(notificationTimer) userInfo:nil repeats:NO];
    self.lblNotification.text = text;
    self.lblNotification.alpha = 0.8;
    self.lblNotification.hidden =- NO;

    return;
}

- (void) userVideoUploaded: (BOOL) success;
{
    if( success )
    {
        [self setNotificationLabel:@"post to facebook complete"];      
        dlLogDebug(@"Video successfully uploaded to facebook and posted");
        [FlurryAnalytics logEvent:@"AVC:FB UP OK"];
    } else {
        [self setNotificationLabel:@"facebook posting failed, check app posting permissions in facebook"];
        [FlurryAnalytics logEvent:@"AVC:FB UP NG"];
    }
    return;
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource
{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	_reloading = YES;
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
	
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
	
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}

- (void) fullscreenExit
{
    [self dismissViewControllerAnimated:NO completion:nil];
    return; 
}

- (void) albumSizeForNextDownloadIsKnown
{
    int prevAlbumSize = self.sizeofAlbumLastTimeQueried;
    int albumCurrentSize = self.album.currentSize;
    
    if (albumCurrentSize == 0)
        return;
    
    if ((prevAlbumSize == albumCurrentSize) || (prevAlbumSize < 1))
        [self.tableView reloadData];
    else if (prevAlbumSize < albumCurrentSize) {
        int offset = 0;
        
        if (self.requestToLoadMore)
            offset = prevAlbumSize;
        
        NSMutableArray * rowIndexPathArray = [[NSMutableArray alloc] initWithCapacity:albumCurrentSize-prevAlbumSize];
        for (int i = 0; i < albumCurrentSize - prevAlbumSize; i++)
            [rowIndexPathArray addObject:[NSIndexPath indexPathForRow:offset + i inSection:0]];
        
        [self stopAllAudio];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:(NSArray*)rowIndexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }         
}

- (void) diafilmCompletedAtIndex:(int) index
{
    if (self.sizeofAlbumLastTimeQueried > index)
    {
        NSMutableArray * rowIndexPathArray = [[NSMutableArray alloc] initWithCapacity:1];
        [rowIndexPathArray addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:rowIndexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

@end
