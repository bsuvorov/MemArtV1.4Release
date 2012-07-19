//
//  UserData.h
//  ContentCreator
//
//  Created by Boris on 5/7/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Album.h"

@protocol UserDataloginDelegate
- (void) userSignedInWithStatus:(BOOL) success;
- (void) userDataPreLoaded: (BOOL) success;
@end

@protocol UserDataFriendsIDsDelegate
- (void) userFriendsRefreshedWithStatus:(BOOL) success FriendListHasChanged:(BOOL) listHasChanged;
@end

@protocol UserUploadDelegate
- (void) userVideoUploaded: (BOOL) success;
@end

@interface UserData : NSObject

@property (readonly) BOOL isAnonymousUser;

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSMutableArray *friendsIds;

@property (nonatomic) int defaultSecondsPriorRecording;

@property (readonly, strong, nonatomic) NSString *userPicFile;
@property (readonly, strong, atomic) Album *userAlbum;
@property (readonly, strong, atomic) Album *publicAlbum;

@property (readonly, nonatomic) BOOL userIDReady;
@property (readonly, nonatomic) BOOL userFriendsIDsReady;

@property (nonatomic, weak) id <UserDataloginDelegate> loginDelegate;
@property (nonatomic, weak) id <UserDataFriendsIDsDelegate> friendsDelegate;
@property (nonatomic, weak) id <UserUploadDelegate> uploadDelegate;

@property (nonatomic, strong) UIManagedDocument *appCDDocument;  // Model is a Core Data database of everything. Might be a bad place, but a good place to start with.

- (void) loginWithFacebook;
- (void) refreshUserFacebooksFriends;

- (void) logOutAndRemoveUserDataWithCompletionBlock:(void (^)(BOOL success)) completionBlock;
- (void) saveData;
- (void) retrieveData;

- (void) postVideoToFacebook:(NSString *) videoFilePath;

- (void) prepareDatabase;

+ (id) singleton;
+ (id) resetSingleton;


- (NSNumber *) getUserId;

@end
