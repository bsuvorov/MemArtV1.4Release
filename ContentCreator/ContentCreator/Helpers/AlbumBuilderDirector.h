//
//  AlbumBuilderDirector.h
//  ContentCreator
//
//  Created by Boris on 3/23/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Diafilm.h"
#import "HelperFunctions.h"

@protocol AlbumBuilderDirectorProtocol
- (void) diafilmFullyDownloaded:(Diafilm *) diafilm;
- (void) singleDiafilmDownloaded:(Diafilm *) diafilm;
- (void) albumDownloadCompleted:(BOOL) success;
- (void) albumNewCountOfDiafilmsCompleted:(BOOL) success;
@end

// forward declaration
@protocol DiafilmsBuilderProtocol;
@protocol AlbumDownloaderDelegateProtocol
- (void) diafilmDownloaded:(Diafilm *) diafilm ByBuilder: (id <DiafilmsBuilderProtocol>) builder;
- (void) tokenArrayReady:(NSArray *) tokenCreationArray FromBuilder: (id <DiafilmsBuilderProtocol>) builder;
@end

@protocol DiafilmsBuilderProtocol

@required
- (void) requestTokensForNewDiafilms:(int) nextDiafilmsCnt BasedOnExistingDiafilms:(NSArray *) activeDiafilms;
- (void) downloadDiafilmBasedOnToken:(NSString *) diafilmToken;
@property (nonatomic, weak) id <AlbumDownloaderDelegateProtocol> director;
@property (nonatomic, weak) RegisteredUser * owner;
@property (nonatomic) BOOL isPublic;
@property (strong, nonatomic) NSArray * listOfFriendsIds;
@optional
- (BOOL) downloadAudioAndImageForDiafilm:(Diafilm *) df;
@end

@interface AlbumBuilderDirector: NSObject  <AlbumDownloaderDelegateProtocol>
{
    id <DiafilmsBuilderProtocol> localBuilder;
    id <DiafilmsBuilderProtocol> serverBuilder;
    NSMutableArray * srvDownloadedDiafilms;
    NSArray * lclStorageTokenCreationArray;
    NSArray * srvStorageTokenCreationArray;
    NSMutableOrderedSet * targetTokens;
    NSArray * albumActiveDiafilms;
    int nextDiafilmsCnt;
    int length;
    int downloadCount;
    BOOL doRefreshCurrentActiveSetOnly;
}

- (id)  initWithLocalBuilder: (id <DiafilmsBuilderProtocol>)lclBuilder RemoteBuilder:(id <DiafilmsBuilderProtocol>) srvBuilder;

- (void) startAsyncDownloadOfMax:(int) numberOfDiafilms 
           GivenExistingDiafilms:(NSArray *) activeDiafilms
         RefreshCurrentActiveSet:(BOOL) refreshCurrentActiveSet;

@property (nonatomic, weak) id <AlbumBuilderDirectorProtocol> builderClient;

@end

@interface ParseAlbumDownloader : NSObject <DiafilmsBuilderProtocol>
{
    NSMutableArray * results;
}

@property (strong, atomic) NSString * albumDirectory;
@end

@interface CoreDataAlbumDownloader : NSObject <DiafilmsBuilderProtocol>
{
    NSArray * matches;
    UIManagedDocument * appDoc;
    NSManagedObjectContext * backgroundContext;
}

@end
