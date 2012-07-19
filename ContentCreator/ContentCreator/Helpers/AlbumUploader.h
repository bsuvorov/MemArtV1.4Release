//
//  AlbumUploader.h
//  ContentCreator
//
//  Created by Boris on 3/24/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RegisteredUser.h"
#import "Diafilm.h"
#import "RegisteredUser.h"

@protocol AlbumUploaderDirectorProtocol
- (void) diafilmUploadedWithToken:(NSString *) token Status: (BOOL) success;
@end

@protocol AlbumUploaderBaseFunctionalityProtocol;
@protocol AlbumUploaderProtocol
- (void) uploadedDiafilmWithToken:(NSString *) token Status: (BOOL) success FromUploader: (id <AlbumUploaderBaseFunctionalityProtocol> ) uploader;
- (void) uploadedDiafilm:(Diafilm *) df Status:(BOOL) success FromUploader:(id <AlbumUploaderBaseFunctionalityProtocol>) uploader;
@end

@protocol AlbumUploaderBaseFunctionalityProtocol

- (id) initForUser:(RegisteredUser *) owner ForAlbumPath:(NSString *) albumPath;
@optional
- (void) uploadQueuedFiles;
- (void) asyncUploadDiafilm:(Diafilm *) df;
- (void) saveDiafilmToUploadQueue:(Diafilm *)df WithPrivacy:(int) privacy;

@property (readonly, atomic) int uploadsPending;

@property (weak, nonatomic) id <AlbumUploaderProtocol> albumDirector;

@end

@interface CoreDataDiafilmUploader : NSObject <AlbumUploaderBaseFunctionalityProtocol>
@end

@interface ParseDiafilmUploader : NSObject <AlbumUploaderBaseFunctionalityProtocol>
{
@private
    NSString *uploadDiafilmsPath;
}
@end

@interface AlbumUploaderDirector : NSObject <AlbumUploaderProtocol>
{
@private
    CoreDataDiafilmUploader * cdUploader;
    ParseDiafilmUploader * peUploder;
}

@property (readonly, nonatomic) int remoteUploadsPending;
@property (nonatomic, weak) id <AlbumUploaderDirectorProtocol> uploaderClient;
- (id) initForUser:(RegisteredUser *) owner ForAlbumPath:(NSString *) albumPath;
- (void) asyncUploadDiafilm:(Diafilm *) df WithPrivacy:(int) privacy;
- (void) asyncUploadQueuedFiles;
@end

    