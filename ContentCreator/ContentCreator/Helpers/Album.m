//
//  Album.m
//  ContentCreator
//
//  Created by Boris on 3/23/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "dlLog.h"
#import "Album.h"
#import "HelperFunctions.h"
#import <Parse/Parse.h>
#import "DiafilmFSSaver.h"
#import "UserData.h"

@interface Album () <AlbumBuilderDirectorProtocol, AlbumUploaderDirectorProtocol>
@property (strong, atomic) NSMutableArray *diafilms;


@property (atomic) BOOL currentlyDownloading;

@property (nonatomic) int currentSize;

@property (strong, nonatomic) RegisteredUser * owner;

@property (strong, nonatomic) NSString *albumPath;

@end

@implementation Album 

#define DEBUG_ALBUM 1

@synthesize diafilms = _diafilms;
@synthesize currentSize = _currentSize;

@synthesize friends  = _friends;
@synthesize userPicPath = _userPicPath;
@synthesize currentlyDownloading = _currentlyDownloading;

@synthesize delegate = _delegate;

@synthesize maxAllowedSize = _maxAllowedSize;

@synthesize owner = _owner;

@synthesize albumPath = _albumPath;
@synthesize isPublic = _isPublic;

- (int) currentSize 
{
    return self.diafilms.count;
}

- (id) initWithUserID:(NSString*) userid UserName: (NSString*) username Name:(NSString *) name
{
    self = [super init];
    
    self.currentSize = 0;

    self.isPublic = NO;
    
    self.diafilms = [[NSMutableArray alloc] init];
    
    NSString * documentsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    self.albumPath = [documentsPath stringByAppendingPathComponent:name];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.albumPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    self.userPicPath = [documentsPath stringByAppendingPathComponent:@"userpic.jpg"];
    
    NSString *uploadFolder = [self.albumPath stringByAppendingPathComponent:@"uploadqueue"];
    [[NSFileManager defaultManager] createDirectoryAtPath:uploadFolder withIntermediateDirectories:NO attributes:nil error:nil];
    
    // this is so ugly, but this is important, since it sets userfeed of parseDownloader to not nil  
    self.friends = nil;

    
    // AI: move user creation FROM ALBUM creation to caller
    NSNumber * intFbUserId = [[NSNumber alloc] initWithLongLong:[userid longLongValue]];
    
    AllUsers * au =  [AllUsers singleton];

    self.owner = [au addUserWithFBId:intFbUserId Name:username UserPicPath:
                  self.userPicPath];
    
    // refresh friend list essentially
    self.friends = nil;
    
    albumUploader = [[AlbumUploaderDirector alloc] initForUser:self.owner ForAlbumPath:self.albumPath];
    albumUploader.uploaderClient = self;
    return self;
}

- (Diafilm *) getDiafilmAtIndex:(int) index
{
    if (index < 0 || index > self.diafilms.count)
        return nil;
    
    return [self.diafilms objectAtIndex:index];
}

- (void) startAsyncLoadfFromLocalStorageXDiafilms:(int) newDiafilmsCntRequest
{
    if (self.currentlyDownloading)
        return;
    
    self.currentlyDownloading = YES;
    self.maxAllowedSize = newDiafilmsCntRequest;
    
    dlLogInfo(@"%s: maxAllowedSize = %d, currentSize = %d, nextDiafilmsCnt = %d", __FUNCTION__, 
              self.maxAllowedSize, self.currentSize, newDiafilmsCntRequest);
    
    CoreDataAlbumDownloader *cdBuilder = [[CoreDataAlbumDownloader alloc] init];
    cdBuilder.owner = self.owner;
    cdBuilder.listOfFriendsIds = self.friends;
    cdBuilder.isPublic = self.isPublic;
    
    albumBuilder = [[AlbumBuilderDirector alloc] initWithLocalBuilder:cdBuilder RemoteBuilder:nil];
    albumBuilder.builderClient = self;

    [albumBuilder startAsyncDownloadOfMax:self.maxAllowedSize GivenExistingDiafilms:self.diafilms RefreshCurrentActiveSet:NO];    

}

- (void) startAsyncLoadFromAllSourcesForNextXDiafilms:(int)nextDiafilmsCnt
{

    if (self.currentlyDownloading)
        return;
    
    self.currentlyDownloading = YES;
    self.maxAllowedSize = self.currentSize + nextDiafilmsCnt;
    
    dlLogInfo(@"%s: maxAllowedSize = %d, currentSize = %d, nextDiafilmsCnt = %d", __FUNCTION__, self.maxAllowedSize, self.currentSize, nextDiafilmsCnt);
    
    CoreDataAlbumDownloader *cdBuilder = [[CoreDataAlbumDownloader alloc] init];
    cdBuilder.owner = self.owner;
    cdBuilder.listOfFriendsIds = self.friends;
    cdBuilder.isPublic = self.isPublic;
    
    ParseAlbumDownloader *peBuilder = nil;

    if (![[UserData singleton] isAnonymousUser])
    {        
        peBuilder = [[ParseAlbumDownloader alloc] init];
        peBuilder.listOfFriendsIds = self.friends;
        peBuilder.albumDirectory = self.albumPath;
        peBuilder.isPublic = self.isPublic;
        peBuilder.owner = self.owner;
    } else if (self.isPublic)
    {
        peBuilder = [[ParseAlbumDownloader alloc] init];
        peBuilder.listOfFriendsIds = nil;
        peBuilder.albumDirectory = self.albumPath;
        peBuilder.isPublic = self.isPublic;        
    }
    
    albumBuilder = [[AlbumBuilderDirector alloc] initWithLocalBuilder:cdBuilder RemoteBuilder:peBuilder];
    albumBuilder.builderClient = self;
    
    if (nextDiafilmsCnt != 0 || self.currentSize == 0)
        [albumBuilder startAsyncDownloadOfMax:self.maxAllowedSize GivenExistingDiafilms:self.diafilms RefreshCurrentActiveSet:NO];    
    else
        [albumBuilder startAsyncDownloadOfMax:self.maxAllowedSize GivenExistingDiafilms:self.diafilms RefreshCurrentActiveSet:YES];    
}


// ascending
- (void) singleDiafilmDownloaded:(Diafilm *) diafilm
{
    @synchronized(self) {
        BOOL inserted = NO;
        if (DEBUG_ALBUM) dlLogDebug(@"Token diafilmDownload = %d", diafilm.intToken);
        
        if (self.diafilms == nil)
            self.diafilms = [[NSMutableArray alloc] init];
        
        if (self.diafilms.count == 0) {
            inserted = YES;
            [self.diafilms addObject:diafilm];
        }
        else {
            Diafilm * firstDf = [self.diafilms objectAtIndex:0];
            Diafilm * lastDf = [self.diafilms lastObject];
            
            if ([diafilm.creationDate compare:firstDf.creationDate] == NSOrderedDescending) {
                inserted = YES;
                    NSLog(@"Inserted diafilm to the begining %@", self.albumPath);
                [self.diafilms insertObject:diafilm atIndex:0];
            } else if ([lastDf.creationDate compare:diafilm.creationDate] == NSOrderedDescending) {
                NSLog(@"Inserted diafilm to the end for album %@", self.albumPath);
                inserted = YES;
                [self.diafilms addObject:diafilm];                
            } else {
                int i;
                Diafilm * df = [self.diafilms objectAtIndex:0];
                for (i = 0; i < self.diafilms.count; i++) {
                    df = [self.diafilms objectAtIndex:i];
                    if ([diafilm.creationDate compare:df.creationDate] == NSOrderedDescending) {
                        inserted = YES;
                        [self.diafilms insertObject:diafilm atIndex:i];
                        break;
                    }
                }
                            
                if ((i == self.diafilms.count) && ([diafilm.creationDate compare:df.creationDate] == NSOrderedAscending)) {
                    [self.diafilms addObject:diafilm];
                    inserted = YES;
                }
                
                if (!inserted) {
                    dlLogCrit(@"Cannot insert dialfilm: <%@:%@:%d>", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__);
                    dlLogCrit(@"Diafilm token str = %@", diafilm.uniqStrToken);
                    for (Diafilm * df in self.diafilms)
                        dlLogCrit(@"diafilms: Diafilm token = %@", diafilm.uniqStrToken);
                    
                    NSAssert(0,@"WTF?");
                }
            }
        }
    }
    
    if (DEBUG_ALBUM) dlLogDebug(@"Downloaded diafilm, diafilm count=%d", self.diafilms.count);
}

- (void) albumDownloadCompleted:(BOOL) success
{
    self.currentlyDownloading = NO;
    
    if (DEBUG_ALBUM) dlLogDebug(@"Album download completed (total=%d)\n", self.currentSize);
    [self.delegate requestedDownloadCompleteWithStatus:success];
}

- (void) albumServerDownloadFailed:(NSError *) error
{
    dlLogCrit(@"Album download failed, do something!\n");
}

- (void) addDiafilmToAlbumWith:(NSString *) tmpImagePath AudioFile: (NSString *) tmpAudioPath
{
}

- (void) addDiafilmToAlbumWith:(NSString *) tmpImagePath AudioFile: (NSString *) tmpAudioPath Permissions:(int) permissions
{
    Diafilm *df = [DiafilmFSSaver buildDiafilmInAlbumPath:self.albumPath
                                                WithToken:[HelperFunctions generateTimeStampRand]
                                                ImagePath:tmpImagePath
                                                AudioPath:tmpAudioPath];
    df.owner = self.owner;
    [self singleDiafilmDownloaded:df];        
    
    [albumUploader asyncUploadDiafilm:df WithPrivacy:permissions];
}


- (void) asyncUploadQueuedFiles
{
    if (![[UserData singleton] isAnonymousUser])
        [albumUploader asyncUploadQueuedFiles];
}


- (void) diafilmUploadedWithToken:(NSString *) token Status: (BOOL) success
{
    // Send push notification to our channel
    NSString *chan = [NSString stringWithFormat:@"channel_%@", self.owner.fbid];
    NSString *message = [NSString stringWithFormat:@"%@ posted new memART!", self.owner.name];
    dlLogInfo(@"Sending notification to channel %@", chan);
    [PFPush sendPushMessageToChannelInBackground:chan withMessage:message];
    
    dispatch_async(dispatch_get_main_queue(), ^{[self.delegate uploadCompleteWithStatus:success];});
}

- (void) albumNewCountOfDiafilmsCompleted:(BOOL) success
{
    [self.delegate albumSizeForNextDownloadIsKnown];
}

- (void) deleteItself
{
    self.diafilms = nil;
    self.diafilms = nil;

    albumUploader.uploaderClient = nil;
    albumBuilder.builderClient = nil;
    
    // remove all files in Album
    [[NSFileManager defaultManager] removeItemAtPath:self.albumPath error:nil];
}

- (void) diafilmFullyDownloaded:(Diafilm *) diafilm
{
    [self.delegate diafilmCompletedAtIndex:[self.diafilms indexOfObject:diafilm]];
}

@end
