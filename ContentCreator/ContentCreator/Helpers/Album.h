//
//  Album.h
//  ContentCreator
//
//  Created by Boris on 3/23/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Diafilm.h"
#import "AlbumBuilderDirector.h"
#import "AlbumUploader.h"
#import "RegisteredUser.h"

@protocol AlbumEvents
- (void) diafilmCompletedAtIndex:(int) index;
- (void) requestedDownloadCompleteWithStatus:(BOOL) success;
- (void) uploadCompleteWithStatus:(BOOL) success;
- (void) albumSizeForNextDownloadIsKnown;
@end

@interface Album : NSObject
{
@private
    AlbumUploaderDirector   *albumUploader;
    AlbumBuilderDirector    *albumBuilder;
}

- (id) initWithUserID:(NSString*) userid UserName: (NSString*) username Name:(NSString *) name;

- (void) addDiafilmToAlbumWith:(NSString *) tmpImagePath AudioFile: (NSString *) tmpAudioPath;
- (void) addDiafilmToAlbumWith:(NSString *) tmpImagePath AudioFile: (NSString *) tmpAudioPath Permissions:(int) permissions;

- (Diafilm *) getDiafilmAtIndex:(int) index;

@property (readonly, nonatomic) int currentSize;
@property (nonatomic) BOOL isPublic;
@property (strong, atomic) NSString *userPicPath;
@property (weak, nonatomic) id <AlbumEvents> delegate;
@property (readonly, strong, nonatomic)  RegisteredUser * owner;

@property (strong, nonatomic) NSMutableArray *friends;


@property (atomic) int maxAllowedSize;
@property (readonly, atomic) BOOL currentlyDownloading;
@property (readonly, strong, nonatomic) NSString *albumPath;

- (void) startAsyncLoadfFromLocalStorageXDiafilms:(int) newDiafilmsCntRequest;
- (void) startAsyncLoadFromAllSourcesForNextXDiafilms:(int)nextDiafilmsCnt;
- (void) asyncUploadQueuedFiles;
- (void) deleteItself;
@end

