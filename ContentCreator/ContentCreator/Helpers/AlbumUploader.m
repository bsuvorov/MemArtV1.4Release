//
//  AlbumUploader.m
//  ContentCreator
//
//  Created by Boris on 3/24/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "AlbumUploader.h"
#import "dlLog.h"
#import "Diafilm.h"
#import "HelperFunctions.h"
#import <Parse/Parse.h>
#import "DiafilmFSSaver.h"
#import "UserData.h"

@interface AlbumUploaderDirector ()

@property (atomic) BOOL srvUploading;

@end

@implementation AlbumUploaderDirector

@synthesize uploaderClient = _uploaderClient;
@synthesize srvUploading = _srvUploading;

- (int) remoteUploadsPending
{
    return peUploder.uploadsPending;
}

- (id) initForUser:(RegisteredUser *) owner ForAlbumPath:(NSString *) albumPath
{
    self = [super init];
    if (self)
    {
        cdUploader = [[CoreDataDiafilmUploader alloc] initForUser:owner ForAlbumPath:albumPath];
        cdUploader.albumDirector = self;
        
        if (owner.name)
        {
            peUploder = [[ParseDiafilmUploader alloc] initForUser:owner ForAlbumPath:albumPath];
            peUploder.albumDirector = self;
        } else {
            peUploder = nil;
        }
        
        self.srvUploading = NO;
    }    
    return self;
}

- (void) asyncUploadDiafilm:(Diafilm *) df WithPrivacy:(int) privacy;
{
    [cdUploader asyncUploadDiafilm:df];

    // add diafilm to upload queue
    [peUploder saveDiafilmToUploadQueue:df WithPrivacy:privacy];
    [self asyncUploadQueuedFiles];
}

- (void) asyncUploadQueuedFiles
{
    dispatch_queue_t uploadQ = dispatch_queue_create("uploader", NULL);
    dispatch_async(uploadQ, ^{
        @synchronized(self) {
            if (self.srvUploading) {
                dlLogWarn(@"AlbumUploader already uploading queued files!!!");
                return;
            }
            self.srvUploading = YES;
        }
        NSLog(@"ENTERED asyncUploadQueue");
        dlLogInfo(@"Client %@", self.uploaderClient);
        [peUploder uploadQueuedFiles];
                
        self.srvUploading = NO;    
        NSLog(@"EXITING asyncUploadQueue");
    });
    dispatch_release(uploadQ);

}

// deprecated. should go away, once uploadqueue of remote uploader switches to rely on core data, instead of local file system
- (void) uploadedDiafilmWithToken:(NSString *) token 
                           Status:(BOOL) success
                     FromUploader:(id <AlbumUploaderBaseFunctionalityProtocol>) uploader
{
    if (uploader == peUploder)
    {
        [self.uploaderClient diafilmUploadedWithToken:token Status:success];
    } else if (uploader == cdUploader)
    {
        NSAssert(0, @"core data uploader should use different delegate callback");
        dlLogInfo(@"Save to core data with status = %d", success);
    } else {
        NSAssert(0, @"Can't find uploder");
    }
}

- (void) uploadedDiafilm:(Diafilm *) df
                  Status:(BOOL) success
            FromUploader:(id <AlbumUploaderBaseFunctionalityProtocol>) uploader
{
    if (uploader == peUploder)
    {
        [self.uploaderClient diafilmUploadedWithToken:df.uniqStrToken Status:success];
    } else if (uploader == cdUploader)
    {
        dlLogInfo(@"Save to core data with status = %d, attempting to async upload to remote", success);
    } else {
        NSAssert(0, @"Can't find uploder");
    }
}
@end

@implementation CoreDataDiafilmUploader

@synthesize albumDirector = _albumDirector;

- (id) initForUser:(RegisteredUser *) owner ForAlbumPath:(NSString *) albumPath;
{
    self = [super init];
    return self;
}

- (void) asyncUploadDiafilm:(Diafilm *) df
{    

    NSArray * diafilmArrayRepr = [[NSArray alloc] initWithObjects:df, nil];
    
    [DiafilmFSSaver saveToCDDiafilmSet:diafilmArrayRepr WithCompletionBlock:^(BOOL success)
    {
        [self.albumDirector uploadedDiafilm:df Status:success FromUploader:self];
    }];
}

@end

@interface ParseDiafilmUploader ()
@property (strong, nonatomic) NSString *userid;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSFileManager *fm;
@property (atomic) int uploadsPending;

@end

@implementation ParseDiafilmUploader
@synthesize albumDirector = _albumDirector;
@synthesize userid = _userid;
@synthesize username = _username;
@synthesize fm = _fm;
@synthesize uploadsPending = _uploadsPending;

- (id) initForUser:(RegisteredUser *) owner ForAlbumPath:(NSString *) albumPath
{
    self = [super init];
    if (self)
    {
        NSAssert(owner, @"Owner is not set in %s", __FUNCTION__);
        NSAssert(owner, @"albumPath is not set in %s", __FUNCTION__);        
        self.userid   = [owner.fbid stringValue];
        self.username = owner.name;
        
        uploadDiafilmsPath = [albumPath stringByAppendingPathComponent:@"uploadqueue"];
        
        self.fm = [NSFileManager defaultManager];
    }
    
    return self;
}

- (void) saveDiafilmToUploadQueue:(Diafilm *)df WithPrivacy:(int) privacy
{
    //
    // Q. why are we doing this if we can simply download everything from Diafilm * df?
    // A. If decision on what to upload vs not upload uploading is entirely done from Core Data, this move makes sense.
    // Howver, because till we rely on local file system as source of uploaded files, 
    // moving to Diafilm * df doesn't buy us much - we'd have to instanciate diafilms from file system.
    // 
    NSString *imageName = [@"image_" stringByAppendingString:df.uniqStrToken];
    NSString *thumbName = [@"thumb_" stringByAppendingString:df.uniqStrToken];
    NSString *audioName = df.uniqStrToken;
    
    NSData * text = [[NSData alloc]initWithBytes:&privacy length:sizeof(privacy)];
    NSString * permissionsName = [df.uniqStrToken stringByAppendingPathExtension:@"perms"];
    NSString *permFilePath = [uploadDiafilmsPath stringByAppendingPathComponent:permissionsName]; 
    [text writeToFile:permFilePath atomically:YES];
    
    NSString *uploadImagePath = [HelperFunctions copyFile:df.imageFile ToFolder:uploadDiafilmsPath WithNewName:imageName Extension:@"jpg"];
    NSString *uploadThumbPath = [HelperFunctions copyFile:df.thumbFile ToFolder:uploadDiafilmsPath WithNewName:thumbName Extension:@"jpg"];
    NSString *uploadAudioPath = [HelperFunctions copyFile:df.audioFile ToFolder:uploadDiafilmsPath WithNewName:audioName Extension:@"caf"];
    
    NSAssert(uploadImagePath && uploadAudioPath && uploadThumbPath,
             @"One of path is nil in %s", __FUNCTION__);
    
}

- (void) uploadQueuedFiles
{            
    NSArray *dirContents = [self.fm contentsOfDirectoryAtPath:uploadDiafilmsPath error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg' and self BEGINSWITH 'image_'"];
    NSArray *onlyJPGs = [dirContents filteredArrayUsingPredicate:fltr];
    
    self.uploadsPending =  onlyJPGs.count; 
    
    if (onlyJPGs.count  > 0)
    {
        NSAssert(self.userid && ![self.userid isEqualToString:@"0"], @"parse uploader userid is not set properly");
        onlyJPGs = [onlyJPGs sortedArrayUsingSelector:@selector(compare:)];
        
        for (NSString* fname in onlyJPGs) {
            NSString *token = [[fname stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"image_" withString:@""];
            
            NSString *audioPath = [[uploadDiafilmsPath stringByAppendingPathComponent:token] stringByAppendingPathExtension:@"caf"];
            NSString *imagePath = [uploadDiafilmsPath stringByAppendingPathComponent:fname];
            NSString *thumbPath = [imagePath stringByReplacingOccurrencesOfString:@"image" withString:@"thumb"];
            
            NSString * permissionsName = [token stringByAppendingPathExtension:@"perms"];
            NSString *permFilePath = [uploadDiafilmsPath stringByAppendingPathComponent:permissionsName]; 
            NSData * perm = [[NSData alloc] initWithContentsOfFile:permFilePath];
            int permissions = 0;
            [perm getBytes:&permissions length:sizeof(permissions)];
            
            [self blockingUploadToParse:imagePath Thumb:thumbPath Audio:audioPath Token:token Permissions:permissions];
        }
    }
}

- (void) blockingUploadToParse:(NSString *) imagePath 
                         Thumb:(NSString *) thumbPath
                         Audio:(NSString *) audioPath
                         Token:(NSString *) token
                   Permissions:(int) permissions
{
    PFObject *diafilmParseSaver = [PFObject objectWithClassName:@"Diafilm"];
    NSData *audioData = [[NSData alloc] initWithContentsOfFile:audioPath];
    PFFile *audioFile = [PFFile fileWithName:@"audio.caf" data:audioData];
    
    NSData *imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
    PFFile *imageFile = [PFFile fileWithName:@"image.jpeg" data:imageData];
    
    NSData *thumbData = [[NSData alloc] initWithContentsOfFile:thumbPath];
    PFFile *thumbFile = [PFFile fileWithName:@"thumb.jpeg" data:thumbData];
    
    
    // if either audio upload or image upload file, simply return
    if (![audioFile save] || ![imageFile save] || ![thumbFile save])
    {
        dlLogWarn(@"Failed to upload auido or image to parse");
        return;
    }
    
    [diafilmParseSaver setObject:self.userid   forKey:@"userid"];
    [diafilmParseSaver setObject:self.username forKey:@"username"];
    [diafilmParseSaver setObject:token forKey:@"token"];
    [diafilmParseSaver setObject:imageFile forKey:@"image"];
    [diafilmParseSaver setObject:audioFile forKey:@"audio"]; 
    [diafilmParseSaver setObject:thumbFile forKey:@"thumb"];
    [diafilmParseSaver setObject:[[NSNumber alloc] initWithInt:permissions] forKey:@"perms"];
    
    if (![diafilmParseSaver save]) 
    {
        dlLogWarn(@"Failed to save diafilm data to parse");
        [self.albumDirector uploadedDiafilmWithToken:token Status:NO FromUploader:self];
    }
    else  {
        dlLogDebug(@"Succeeded saving diafilm data to parse");
        
        [self.fm removeItemAtPath:audioPath error:nil];
        [self.fm removeItemAtPath:imagePath error:nil];
        [self.fm removeItemAtPath:thumbPath error:nil];

        [DiafilmFSSaver updateDateOfDiafilmWithToken:[HelperFunctions extractIntFromToken:token] 
                                              ToDate:diafilmParseSaver.createdAt];
        
        [self.albumDirector uploadedDiafilmWithToken:token Status:YES FromUploader:self];
        
        self.uploadsPending =  self.uploadsPending - 1; 
    }
}


@end

