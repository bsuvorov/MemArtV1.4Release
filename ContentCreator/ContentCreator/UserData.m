//
//  UserData.m
//  ContentCreator
//
//  Created by Boris on 5/7/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "UserData.h"
#import "globalDefines.h"
#import <Parse/Parse.h>
#import "dlLog.h"
#import "CDCleaner.h"
#import "FlurryAnalytics.h"

static UserData * userData = nil;

@interface UserData () <PF_FBDialogDelegate, PF_FBRequestDelegate>

@property (strong, nonatomic) NSString *userPicFile;

@property (nonatomic) BOOL userIDReady;
@property (nonatomic) BOOL userFriendsIDsReady;

@end


@implementation UserData

#define DEBUG_FACEBOOK 0
@synthesize isAnonymousUser = _isAnonymousUser;
@synthesize userIDReady         = _userIDReady;
@synthesize userFriendsIDsReady = _userFriendsIDsReady;

@synthesize loginDelegate = _loginDelegate;
@synthesize friendsDelegate = _friendsDelegate;
@synthesize uploadDelegate = _uploadDelegate;

@synthesize userId = _userId;
@synthesize userName = _userName;
@synthesize friendsIds = _friendsIds;
@synthesize userPicFile = _userPicFile;
@synthesize userAlbum = _userAlbum;
@synthesize publicAlbum = _publicAlbum;
@synthesize defaultSecondsPriorRecording = _defaultSecondsPriorRecording;

@synthesize appCDDocument = _appCDDocument;


- (BOOL) isAnonymousUser
{
    BOOL Anonymous = userData.userName == nil;
    return Anonymous;
}

- (void) setFriendsDelegate:(id<UserDataFriendsIDsDelegate>)friendsDelegate
{
    _friendsDelegate = friendsDelegate;
}

+ (id) resetSingleton
{
    @synchronized(self) {
        userData = [[self alloc] init];
        [userData retrieveData];
        userData.userIDReady = ([PFUser currentUser] != nil) && (userData.userId != nil);
    }
    return userData;    
}

+ (id) singleton
{
    @synchronized(self) {
        if (userData == nil) {
            userData = [[self alloc] init];
            [userData retrieveData];
            userData.userIDReady = ([PFUser currentUser] != nil) && (userData.userId != nil);
        }
    }
    return userData;
}

- (void)dealloc
{    
    [self.appCDDocument closeWithCompletionHandler:^(BOOL success) {}];
}


- (void) setDefaultSecondsPriorRecording:(int)defaultSecondsPriorRecording
{
    if (_defaultSecondsPriorRecording != defaultSecondsPriorRecording) {
        NSNumber * countdownValue = [[NSNumber alloc] initWithInt:defaultSecondsPriorRecording];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:countdownValue forKey:USER_DEFAULT_COUNTDOWN_VALUE_KEY];
        [defaults synchronize];        
    }
    _defaultSecondsPriorRecording = defaultSecondsPriorRecording;
}

- (NSMutableArray*) friendsIds
{
    if (_friendsIds == nil) 
        _friendsIds = [[NSMutableArray alloc] init];
    
    return _friendsIds;
}

- (Album *) publicAlbum
{
    if (_publicAlbum == nil)
    {
        _publicAlbum = [[Album alloc] initWithUserID:self.userId UserName:self.userName Name:DEMOALBUMNAME];
        _publicAlbum.isPublic = YES;
        _publicAlbum.maxAllowedSize = DEFAULT_ALBUM_SIZE_ON_STARTUP;
        _publicAlbum.friends = nil;
    }
    
    return _publicAlbum;
}



- (Album *) userAlbum
{
    if (_userAlbum == nil)
    {
        if (self.userId != nil && self.userName != nil && self.friendsIds != nil) {
            _userAlbum = [[Album alloc] initWithUserID: self.userId UserName:self.userName  Name:@"wall"];
            _userAlbum.maxAllowedSize = DEFAULT_ALBUM_SIZE_ON_STARTUP;
            _userAlbum.friends = self.friendsIds;
            
        } else {
            _userAlbum = [[Album alloc] initWithUserID: nil UserName:nil  Name:@"anonymous"];
            _userAlbum.maxAllowedSize = DEFAULT_ALBUM_SIZE_ON_STARTUP;
            _userAlbum.friends = nil;            
            dlLogWarn(@"Failed to get allocate user album due to missing user data");
        }
    }

    return _userAlbum;
}

- (id) init
{
    if (self = [super init]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                             NSUserDomainMask, YES);
        NSString *appDocumentDirectory = [paths lastObject];
        self.userPicFile  = [appDocumentDirectory stringByAppendingPathComponent:@"userpic.jpg"];
        
        [self retrieveData];
        
        self.userId = nil;
        self.userName = nil;
        self.friendsIds = nil;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber * countDownSeconds = [defaults objectForKey:USER_DEFAULT_COUNTDOWN_VALUE_KEY];
        if (countDownSeconds == nil) {
            countDownSeconds = [[NSNumber alloc] initWithInt:3];
            [defaults setObject:countDownSeconds forKey:USER_DEFAULT_COUNTDOWN_VALUE_KEY];
            [defaults synchronize];
        }
        _defaultSecondsPriorRecording = countDownSeconds.intValue;
    }
    return self;
}

- (void) saveData
{
    if (self == nil) {
        dlLogWarn(@"Singleton is NIL!");
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (userData.userId != nil)
        [defaults setObject:userData.userId forKey:@"userid"];
    
    if (userData.userName != nil)
        [defaults setObject:userData.userName forKey:@"username"];

    if (userData.friendsIds != nil)
        [defaults setObject:userData.friendsIds forKey:@"friends"];    
    
    [defaults synchronize];
}

- (void) retrieveData
{
    if (self == nil) {
        dlLogWarn(@"Singleton is NIL!");
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.userId     = [defaults objectForKey:@"userid"];
    self.userName   = [defaults objectForKey:@"username"];
    self.friendsIds = [defaults objectForKey:@"friends"];    
}

- (void) logOutAndRemoveUserDataWithCompletionBlock:(void (^)(BOOL success)) completionBlock;
{
    [PFUser logOut];
    PF_Facebook *fbAcc = [PFFacebookUtils facebook];
    [fbAcc logout];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"userid"];
    [defaults removeObjectForKey:@"username"];

    [_userAlbum deleteItself];

    // unsubscribe from notification channels.
    [HelperFunctions unsubscribeFromAllChannels];
    
    self.userId = 0;
    self.userIDReady = NO;
    self.userFriendsIDsReady = NO;
    
    self.loginDelegate = nil;
    self.friendsDelegate = nil;
    self.uploadDelegate = nil;
    self.userName = nil;
    self.friendsIds = nil;
    self.userPicFile = nil;
    _userAlbum = nil;
    _publicAlbum = nil;
    
    [CDCleaner removeEverythingButAnonymousUserPostsWithCompletionBlock:^(BOOL success){
         [self.appCDDocument closeWithCompletionHandler:^(BOOL success) {
             self.appCDDocument = nil;                          
             completionBlock(success);        
         }];        
     }];    
}

- (void) loginWithFacebook
{
    _userAlbum = nil;
    _publicAlbum = nil;
    
    if (self.loginDelegate == nil)
    {
        NSAssert(0, @"loginning in with facebook required login delegate");
    }
    
    // Ask for permissions to post to the stream
    NSArray* permissions = [[NSArray alloc] initWithObjects:
                            @"publish_stream", nil];
    
    [PFFacebookUtils logInWithPermissions:permissions block:^(PFUser *user, NSError *error) {
        if (!user) {
            dlLogInfo(@"Uh oh. The user cancelled the Facebook login.");
            [self.loginDelegate userSignedInWithStatus:NO]; 
        } else {
            dlLogInfo(@"User logged in through Facebook!");
            PF_Facebook *fbAcc = [PFFacebookUtils facebook];

            self.userIDReady = false;
            self.userFriendsIDsReady = false;
            [fbAcc requestWithGraphPath:FB_FRIENDS_GRAPH_PATH andDelegate:self];            
            [fbAcc requestWithGraphPath:FB_ME_GRAPH_PATH andDelegate:self];
        }
    }];    
}

- (void) postVideoToFacebook:(NSString *) videoFilePath
{
    NSData *videoData = [NSData dataWithContentsOfFile:videoFilePath];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSString * date = [dateFormatter stringFromDate:[NSDate date]];
    dlLogDebug(@"date: %@", date);
    
    NSString * videoTitle = [NSString stringWithFormat:@"Created with memArt on %@", date];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   videoData, @"video.mov",
                                   @"video/quicktime", @"contentType",
                                   videoTitle, @"title",
                                   @"Press Play to hear this picture", @"description",
                                   nil];
    PF_Facebook *fbAcc = [PFFacebookUtils facebook];
    dlLogDebug(@"Calling FB Function for upload");
    [fbAcc requestWithGraphPath:FB_VIDEO_GRAPH_PATH andParams:params andHttpMethod:@"POST" andDelegate:self];
}
    
     
- (void) refreshUserFacebooksFriends
{
    PF_Facebook *fbAcc = [PFFacebookUtils facebook];
    [fbAcc requestWithGraphPath:FB_FRIENDS_GRAPH_PATH andDelegate:self];
}

/**
 * Called when a request returns and its response has been parsed into
 * an object.
 *
 * The resulting object may be a dictionary, an array or a string, depending
 * on the format of the API response. If you need access to the raw response,
 * use:
 */

- (NSMutableArray *) createArrayOfFriendsFromFBResultDict: (NSDictionary *) result
{
    NSMutableArray *friendsIds = [[NSMutableArray alloc] init];
    if ([result isKindOfClass:[NSDictionary class]]) 
    {
        //ok so it's a dictionary with one element (key="data"), which is an array of dictionaries, each with "name" and "id" keys
        NSArray *items = [(NSDictionary *)result objectForKey:@"data"];
        for (NSDictionary *friend in items) {
            NSString* friendId = [friend objectForKey:@"id"];
            [friendsIds addObject:friendId];
        }
    }
    
    return friendsIds;
}

- (void) saveFBUserPicToPath:(NSString *) path WithId:(NSString *) userid
{
    NSData *userPic = [HelperFunctions fetchFBUserPicFromUserId:userid];
    [userPic writeToFile:path atomically:YES];
}

- (void) addSelfIdFromFBResultDict: (NSDictionary *) result
{
    UserData *ud = [UserData singleton];
    NSDictionary * resultDict = (NSDictionary *) result;
    ud.userId = [resultDict objectForKey:@"id"];
    ud.userName = [resultDict objectForKey:@"name"];
    [self saveFBUserPicToPath:ud.userPicFile WithId:ud.userId];
    [ud saveData];    
}

- (void)request:(PF_FBRequest *)request didFailWithError:(NSError *)error
{
    if ([request.url isEqualToString:FB_FRIENDS_REQUEST_STRING]) {
        dlLogWarn(@"Failed to fetch user friends list");
        self.userFriendsIDsReady = NO;
        [self.friendsDelegate userFriendsRefreshedWithStatus:NO FriendListHasChanged:NO];
    }
    
    if ([request.url isEqualToString:FB_ME_REQUEST_STRING]) {
        dlLogWarn(@"User id failed to load from facebook, can't move on to offline mode");
        self.userIDReady = NO;
        [self.loginDelegate userSignedInWithStatus:NO];
    }
    
    if ([request.url isEqualToString:FB_VIDEO_REQUEST_STRING]) 
    {
        dlLogWarn(@"Do not have rights or something went wrong to post video's to users graph");
        [self.uploadDelegate userVideoUploaded:NO];
    }
    
}

- (void)request:(PF_FBRequest *)request didLoad:(id)result
{    
    if ([request.url isEqualToString:FB_ME_REQUEST_STRING]) {
        [self addSelfIdFromFBResultDict:result];
        self.userIDReady  = YES;
        [self.loginDelegate userSignedInWithStatus:YES]; 
    }
    
    if ([request.url isEqualToString:FB_FRIENDS_REQUEST_STRING]) {
        NSMutableArray * newFriendsIDs = [self createArrayOfFriendsFromFBResultDict:result];
        NSSet * oldFriendsSet = [[NSSet alloc] initWithArray:self.friendsIds];
        NSSet * newFriendsSet = [[NSSet alloc] initWithArray:newFriendsIDs];
        
        if ([oldFriendsSet isEqualToSet:newFriendsSet])
            [self.friendsDelegate userFriendsRefreshedWithStatus:YES FriendListHasChanged:NO];
        else {
            UserData *ud = [UserData singleton];

            dispatch_queue_t notificationSubscriberQ = dispatch_queue_create("notificationSubscriberQ", NULL);
            dispatch_async(notificationSubscriberQ, ^{
                [HelperFunctions subscribeToChannelsOfNewFriends:newFriendsIDs WithoutResubscribingToOldFriends:ud.friendsIds];
                [HelperFunctions unsubscribeFromChannelOfRemovedFriends:newFriendsIDs WithoutResubscribingToOldFriends:ud.friendsIds];        
            });    
            dispatch_release(notificationSubscriberQ);
            ud.friendsIds = newFriendsIDs;
            [ud saveData];
            
            [self.friendsDelegate userFriendsRefreshedWithStatus:YES FriendListHasChanged:YES];
        }
        self.userFriendsIDsReady = YES;
        
        if (DEBUG_FACEBOOK)
            for (NSString* friendId in newFriendsIDs)
                dlLogDebug(@"id=%@", friendId);

    }

    if ([request.url isEqualToString:FB_VIDEO_REQUEST_STRING])
    {
        [self.uploadDelegate userVideoUploaded:YES];
        dlLogInfo(@"Video posted to Facebook");
    }
}


- (void) prepareDatabase
{
    // if it is first time starting the app, we need to register and create database.
    if (!self.appCDDocument) 
    {  
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"DiafilmCD_2"];
        self.appCDDocument = [[UIManagedDocument alloc] initWithFileURL:url];
    } else {
        [self.loginDelegate userDataPreLoaded:YES];
    }
    
}

- (void)useDocument
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.appCDDocument.fileURL path]]) {
        // does not exist on disk, so create it
        [self.appCDDocument saveToURL:self.appCDDocument.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success)
            {
                NSLog(@"CDDocument created.");
                [self.appCDDocument openWithCompletionHandler:^(BOOL success) {
                    NSLog(@"CDDocument opened");
                    [self.loginDelegate userDataPreLoaded:YES];
                }];
            } else {
                NSAssert(0, @"Failed to create file");
            }
        }];
    } else if (self.appCDDocument.documentState == UIDocumentStateClosed) {
        // exists on disk, but we need to open it
        [self.appCDDocument openWithCompletionHandler:^(BOOL success) {
            NSLog(@" user data preloaded, UIDocumentStateClosed");
            [self.loginDelegate userDataPreLoaded:YES];
        }];
    } else if (self.appCDDocument.documentState == UIDocumentStateNormal) {
        NSLog(@" user data preloaded, UIDocumentStateNormal");
        [self.loginDelegate userDataPreLoaded:YES];
    }
}


- (void)setAppCDDocument:(UIManagedDocument *)appCDDocument
{
    if (_appCDDocument != appCDDocument) {
        _appCDDocument = appCDDocument;
        if (appCDDocument != nil)
            [self useDocument];
    }
}

- (NSNumber *) getUserId
{
    return [NSNumber numberWithDouble:[self.userId doubleValue]];
}

@end
