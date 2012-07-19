//
//  AlbumBuilderDirector.m
//  ContentCreator
//
//  Created by Boris on 3/23/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "AlbumBuilderDirector.h"
#import "dlLog.h"
#import "Diafilm.h"
#import <Parse/Parse.h>
#import "RegisteredUser.h"
#import "CDUser+Model.h"
#import "CDDiafilm+Model.h"
#import "UserData.h"
#import "globalDefines.h"
#import "dlLog.h"
#import "DiafilmFSSaver.h"

@interface TokenCreationSearchItem : NSObject
@property (strong, nonatomic) NSDate * creationDate;
@property (strong, nonatomic) NSString * token;

-(NSInteger) timeStampCompare: (TokenCreationSearchItem *) tcsi2;
@end

@implementation TokenCreationSearchItem 
@synthesize creationDate = _creationDate;
@synthesize token = _token;

- (id) initWithToken:(NSString *) token CreationDate:(NSDate *) creationDate
{
    self = [super init];
    if (self)
    {
        self.token = token;
        self.creationDate = creationDate;
    }
    return  self;
}

- (NSInteger) timeStampCompare: (TokenCreationSearchItem *) tcsi2
{
    if ([self.creationDate compare:tcsi2.creationDate] == NSOrderedDescending)
        return -1;
    else if ([self.creationDate compare:tcsi2.creationDate] == NSOrderedAscending)
        return 1;
    else 
        return 0;
}

+ (NSSet *) createTokenSetFromTCSIArray:(NSArray *) array
{
    NSMutableSet * storageTokens = [[NSMutableSet alloc] initWithCapacity:array.count];
    for (TokenCreationSearchItem * tcsi in array)
        [storageTokens addObject:tcsi.token];  
    
    return storageTokens;
}

@end

@implementation AlbumBuilderDirector

@synthesize builderClient = _builderClient;


- (id)  initWithLocalBuilder: (id <DiafilmsBuilderProtocol>)lclBuilder RemoteBuilder:(id <DiafilmsBuilderProtocol>) srvBuilder
{
    self = [super init];
    if (self)
    {
        serverBuilder = srvBuilder;
        serverBuilder.director = self;
        localBuilder = lclBuilder;
        localBuilder.director = self;
        srvDownloadedDiafilms = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addDiafilm: (Diafilm *) df
{
    @synchronized(self) {
        downloadCount++;
        dlLogInfo(@"Downloaded %d diafilm with token %@", downloadCount, df.uniqStrToken);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.builderClient singleDiafilmDownloaded:df];
        });
    }
}

- (void) diafilmDownloaded:(Diafilm *) diafilm ByBuilder:(id <DiafilmsBuilderProtocol>) builder
{
    if (builder == serverBuilder)
        [srvDownloadedDiafilms addObject:diafilm];

    [self addDiafilm:diafilm];

}

- (void) startAsyncDownloadOfMax:(int) numberOfDiafilms 
           GivenExistingDiafilms:(NSArray *) activeDiafilms
         RefreshCurrentActiveSet:(BOOL) refreshCurrentActiveSet
{        
    targetTokens = nil;
    lclStorageTokenCreationArray = srvStorageTokenCreationArray = nil;
    albumActiveDiafilms = activeDiafilms;
    // don't remove this line, it is being used in other places in the code
    nextDiafilmsCnt = numberOfDiafilms;
    
    doRefreshCurrentActiveSetOnly = refreshCurrentActiveSet;

    dispatch_queue_t downloadQueue = dispatch_queue_create("downloader", NULL);
    dispatch_async(downloadQueue, ^{
        [serverBuilder requestTokensForNewDiafilms:nextDiafilmsCnt BasedOnExistingDiafilms:activeDiafilms];
        [localBuilder requestTokensForNewDiafilms:nextDiafilmsCnt BasedOnExistingDiafilms:activeDiafilms];
    });    
    dispatch_release(downloadQueue);
}

- (void) startIndividualDownload
{
    BOOL atLeastOneTokenWasntActive = NO;
    
    NSMutableSet * activeAlbumTokens = [[NSMutableSet alloc]initWithCapacity:albumActiveDiafilms.count];
    for (Diafilm * df in albumActiveDiafilms)
        [activeAlbumTokens addObject:df.uniqStrToken];
    
    // create local and server token sets
    NSSet * lclStorageTokens = [TokenCreationSearchItem createTokenSetFromTCSIArray:lclStorageTokenCreationArray];
    NSSet * srvStorageTokens = [TokenCreationSearchItem createTokenSetFromTCSIArray:srvStorageTokenCreationArray];

    // merge srv and lcl token/creation searchable items, so that if srv token is present in lcl, it doesn't get added
    NSMutableArray * targetTCSIs = [[NSMutableArray alloc] initWithArray:lclStorageTokenCreationArray];
    for (TokenCreationSearchItem * tcsi in srvStorageTokenCreationArray)
        if (![lclStorageTokens containsObject:tcsi.token])
            [targetTCSIs addObject:tcsi];

    NSMutableSet *localSrvDiffernce = [[NSMutableSet alloc] initWithSet:activeAlbumTokens];
    [localSrvDiffernce minusSet:srvStorageTokens];
    
    NSMutableSet *localCDDiffernce = [[NSMutableSet alloc] initWithSet:activeAlbumTokens];
    [localCDDiffernce minusSet:lclStorageTokens];

    // sort targetTCSIs
    [targetTCSIs sortUsingSelector:@selector(timeStampCompare:)];
    
    downloadCount = 0;

    if (doRefreshCurrentActiveSetOnly)
    {
        // find least length out of two length to not override size
        length = (activeAlbumTokens.count > targetTCSIs.count) ? targetTCSIs.count : activeAlbumTokens.count;
        NSLog(@"doRefreshCurrentActiveSetOnly length = %d, nextDiafilmsCnt = %d, activeAlbumTokens.count = %d, targetTCSIs.count = %d", 
              length, nextDiafilmsCnt, activeAlbumTokens.count, targetTCSIs.count);
    } else {
        // find least length out of two length to not override size        
        length = nextDiafilmsCnt - activeAlbumTokens.count;
        length = (length > targetTCSIs.count) ? targetTCSIs.count : length;
        NSLog(@"length = %d, nextDiafilmsCnt = %d, activeAlbumTokens.count = %d, targetTCSIs.count = %d",
              length, nextDiafilmsCnt, activeAlbumTokens.count, targetTCSIs.count);
    }
    
    if (srvStorageTokenCreationArray)
    {
        for (int i = 0; i < length; i++)
        {
            // it is here to prevent crash on download and simulatenous FB sign out
            if (self.builderClient == nil)
                return;
            
            TokenCreationSearchItem * tcsi = [targetTCSIs objectAtIndex:i];
            NSString * token = tcsi.token;
            
            if ([activeAlbumTokens containsObject:token])
            {
                if ([lclStorageTokens containsObject:token])
                {
    
                    dlLogWarn(@"*************************************************************************");
                    dlLogWarn(@"Active album tokens contains object which was prefetched by CD!");
                    dlLogWarn(@"*************************************************************************");                
                }
                continue;
            }
            
            atLeastOneTokenWasntActive = YES;

            
                    
            if ([lclStorageTokens containsObject:tcsi.token])
            {
                dlLogInfo(@"Downloading from local builder Diafilm with token %@", token);
                [localBuilder downloadDiafilmBasedOnToken:token];
            }
            else  if ([srvStorageTokens containsObject:token])
            {
                dlLogInfo(@"Downloading from server builder Diafilm with token %@", token);
                [serverBuilder downloadDiafilmBasedOnToken:token];
            }
            else 
                NSAssert(0, @"Can't find token in either of local or server token sets");        
        } 
    }
    else {
        for (int i = 0; i < length; i++)
        {
            TokenCreationSearchItem * tcsi = [targetTCSIs objectAtIndex:i];
            NSString * token = tcsi.token;

            dlLogInfo(@"Attempting to download token %@", token);

            if ([activeAlbumTokens containsObject:token])
            {
                dlLogWarn(@"*************************************************************************");
                dlLogWarn(@"Active album tokens contains object which was prefetched by CD!");
                dlLogWarn(@"*************************************************************************");                
                continue;
            }
            
            atLeastOneTokenWasntActive = YES;
            
            if ([lclStorageTokens containsObject:token])
                [localBuilder downloadDiafilmBasedOnToken:token];
            
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.builderClient albumNewCountOfDiafilmsCompleted:YES];
    });

    for (Diafilm * df in srvDownloadedDiafilms)
    {
        // if at least one item fails to download exit immediately and discard rest.
        if (![serverBuilder downloadAudioAndImageForDiafilm:df])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.builderClient albumDownloadCompleted:NO];
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.builderClient diafilmFullyDownloaded:df];
        });
        
    }
    
    if (self.builderClient)
    {
        [DiafilmFSSaver saveToCDDiafilmSet:srvDownloadedDiafilms WithCompletionBlock:^(BOOL success){

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.builderClient albumDownloadCompleted:YES];
            });
        }];
    }

}

- (void) tokenArrayReady:(NSArray *) tokenCreationArray 
             FromBuilder:(id <DiafilmsBuilderProtocol>) builder
{
    @synchronized(self) {
        if (serverBuilder && (builder == serverBuilder))
            srvStorageTokenCreationArray = tokenCreationArray;
        else if (localBuilder && (builder == localBuilder))
            lclStorageTokenCreationArray = tokenCreationArray;
        else
            NSAssert(0, @"Can't find pointre to private builder object (server or local)");
        
        // support for single builder case
        if ((!localBuilder || lclStorageTokenCreationArray) && 
            (!serverBuilder || srvStorageTokenCreationArray))
            [self startIndividualDownload];

        // in case when there is no internet connection and server builder reports nil as result.
        if (localBuilder && lclStorageTokenCreationArray && 
            serverBuilder && !srvStorageTokenCreationArray)
            [self startIndividualDownload];
    }           
}
@end


@implementation CoreDataAlbumDownloader

@synthesize director = _director;
@synthesize owner = _owner;
@synthesize isPublic = _isPublic;
@synthesize listOfFriendsIds = _listOfFriendsIds;

- (void) requestTokensForNewDiafilms:(int) nextDiafilmsCnt BasedOnExistingDiafilms:(NSArray *) activeDiafilms
{
    appDoc = [[UserData singleton] appCDDocument];
    backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = appDoc.managedObjectContext;
    
    matches = nil;
    NSMutableOrderedSet * __block localTokens = nil;
    
    [backgroundContext performBlockAndWait:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CDDiafilm"];
        Diafilm * lastActiveDiafilm = [activeDiafilms lastObject];
        
        if (self.isPublic) {
            // if we're requesting more than we have, we look for next X diafilms
            if (nextDiafilmsCnt != activeDiafilms.count && activeDiafilms.count != 0)
                request.predicate = [NSPredicate predicateWithFormat:@"creationDate <= %@ and thumbPath CONTAINS 'public'", lastActiveDiafilm.creationDate];
            else 
                request.predicate = [NSPredicate predicateWithFormat:@"thumbPath CONTAINS 'public'", lastActiveDiafilm.creationDate];
        } else {
            // if we're requesting more than we have, we look for next X diafilms
            if (nextDiafilmsCnt != activeDiafilms.count && activeDiafilms.count != 0)
                // why not simply use 'wall'? Because we have to count on for 'anonymous' ...
                request.predicate = [NSPredicate predicateWithFormat:@"creationDate <= %@ and NOT ( thumbPath CONTAINS 'public' )", lastActiveDiafilm.creationDate];
            else
                request.predicate = [NSPredicate predicateWithFormat:@"NOT (thumbPath CONTAINS 'public')"];
        }
        request.fetchLimit = nextDiafilmsCnt;
        //request.fetchOffset = activeDiafilms.count; 
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
        request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];

        NSError *error = nil;
        matches = [backgroundContext executeFetchRequest:request error:&error];
    
        
        if (!matches) {
            // handle error
        } else {
            dlLogInfo(@"Fetched %d diafilms from Core Data", matches.count);
            localTokens = [[NSMutableOrderedSet alloc] init];
            for (CDDiafilm * cdDiafilm in matches) 
            {
                TokenCreationSearchItem * tcsi = [[TokenCreationSearchItem alloc] 
                                                  initWithToken:cdDiafilm.strToken 
                                                  CreationDate:cdDiafilm.creationDate];
                [localTokens addObject:tcsi];
            }
        }
    }];  
    
    [self.director tokenArrayReady:localTokens.array FromBuilder:self];
}

- (void) downloadDiafilmBasedOnToken:(NSString *) diafilmToken
{
    // assumes that matches still exist.
    // if this is not true anymore, we'd need to run fetch again for exact diafilmToken
    for (CDDiafilm * cdDiafilm in matches)
    {
        if ([cdDiafilm.strToken isEqualToString:diafilmToken])
        {
            Diafilm * __block df = nil;
            [backgroundContext performBlockAndWait:^{
                df = [CDDiafilm createModelDiafilmFromCDDiafilm:cdDiafilm inManagedObjectContext:backgroundContext];
            }];
             
            [self.director diafilmDownloaded:df ByBuilder:self];
            return;
        }
    }
    
    NSAssert(0, @"Make sure fetchOffset hack is still working!");
    
}

@end


@implementation ParseAlbumDownloader

@synthesize director = _director;
@synthesize listOfFriendsIds = _listOfFriendsIds;
@synthesize albumDirectory = _albumDirectory;
@synthesize owner = _owner;
@synthesize isPublic = _isPublic;


- (PFQuery *) formQueryForFBFriendsVisbileTokens:(int) nextDiafilmsCnt BasedOnExistingDiafilms:(NSArray *) activeDiafilms
{
    PFQuery *query = [PFQuery queryWithClassName:@"Diafilm"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    query.limit = nextDiafilmsCnt;
    
    [query whereKey:@"userid" containedIn:self.listOfFriendsIds];
    NSNumber * permsNumber = [[NSNumber alloc] initWithInt:DF_PRIVACY_FB];
    [query whereKey:@"perms" greaterThanOrEqualTo:permsNumber];
    
    // if we're requesting count which is not equal to current count, we request X more diafilms
    if (!(nextDiafilmsCnt == activeDiafilms.count) && activeDiafilms.count != 0)
    {
        Diafilm * lastActiveDiafilm = [activeDiafilms lastObject];    
        [query whereKey:@"createdAt" lessThanOrEqualTo:lastActiveDiafilm.creationDate];
    }
    
    [query orderByDescending:@"createdAt"];
    
    return query;
}

- (PFQuery *) formQueryForOwnUserTokens:(int) nextDiafilmsCnt BasedOnExistingDiafilms:(NSArray *) activeDiafilms
{
    NSAssert(self.owner.fbid, @"own userid is set to nil!");
    
    PFQuery *query = [PFQuery queryWithClassName:@"Diafilm"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    query.limit = nextDiafilmsCnt;
    

    NSString * userIdStr = [self.owner.fbid stringValue];
    [query whereKey:@"userid" equalTo:userIdStr];
    
    // if we're requesting count which is not equal to current count, we request X more diafilms
    if (!(nextDiafilmsCnt == activeDiafilms.count) && activeDiafilms.count != 0)
    {
        Diafilm * lastActiveDiafilm = [activeDiafilms lastObject];    
        [query whereKey:@"createdAt" lessThanOrEqualTo:lastActiveDiafilm.creationDate];
    }
    
    [query orderByDescending:@"createdAt"];
    
    return query;
}

- (PFQuery *) formQueryForPublicTokens:(int) nextDiafilmsCnt BasedOnExistingDiafilms:(NSArray *) activeDiafilms
{    
    PFQuery *query = [PFQuery queryWithClassName:@"Diafilm"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    query.limit = nextDiafilmsCnt;
    
    NSNumber * permsNumber = [[NSNumber alloc] initWithInt:DF_PRIVACY_PUBLIC_APPROVED];
    [query whereKey:@"perms" equalTo:permsNumber];
    
    // if we're requesting count which is not equal to current count, we request X more diafilms
    if (!(nextDiafilmsCnt == activeDiafilms.count) && activeDiafilms.count != 0)
    {
        Diafilm * lastActiveDiafilm = [activeDiafilms lastObject];    
        [query whereKey:@"createdAt" lessThanOrEqualTo:lastActiveDiafilm.creationDate];
    }
    
    [query orderByDescending:@"createdAt"];
    
    return query;
}

- (NSMutableArray *) runQuery:(PFQuery *) query
{
    NSError *error = nil;
    
    NSArray * tmpResults = [query findObjects:&error];
    dlLogDebug(@"Fetched results count %d", results.count);
    NSMutableArray * serverTokenCreationArray = nil;
    
    if (error)
    {
        dlLogWarn(@"Failed to fetch in %s", __FUNCTION__);
        [self.director tokenArrayReady:nil FromBuilder:self];
    } else {
        serverTokenCreationArray = [[NSMutableArray alloc] initWithCapacity:results.count];
        for (PFObject *pfDiafilm in tmpResults) 
        {
            
            [serverTokenCreationArray addObject:
             [[TokenCreationSearchItem alloc] 
              initWithToken:[pfDiafilm  objectForKey:@"token"]
              CreationDate:pfDiafilm.createdAt]];
        }
        
        [results addObjectsFromArray:tmpResults];
    }    

    
    return serverTokenCreationArray;
}

- (void) requestTokensForNewDiafilms:(int) nextDiafilmsCnt BasedOnExistingDiafilms:(NSArray *) activeDiafilms
{    

    
    NSMutableArray * resultRun = nil;
    
    // reset results for each run, because it is used as cache for multiple queries
    // Ssee !isPublic case - 2 runQuery calls. It requires special handling.
    results = [[NSMutableArray alloc] init];
    if (self.isPublic)
    {
        PFQuery * query = [self formQueryForPublicTokens:nextDiafilmsCnt BasedOnExistingDiafilms:activeDiafilms];
        resultRun = [self runQuery:query];
    } else {
        if (self.listOfFriendsIds.count == 0 && self.owner.fbid == nil)
        {
            [self.director tokenArrayReady:nil FromBuilder:self];
            return;
        }

        PFQuery * fbFriendsQuery = [self formQueryForFBFriendsVisbileTokens:nextDiafilmsCnt BasedOnExistingDiafilms:activeDiafilms];
        PFQuery * privateQuery = [self formQueryForOwnUserTokens:nextDiafilmsCnt BasedOnExistingDiafilms:activeDiafilms];
        
        NSMutableArray * privateRun = [self runQuery:privateQuery];
        NSMutableArray * fbFriendsRun = [self runQuery:fbFriendsQuery];        
        
        resultRun = [[NSMutableArray alloc] init];
        [resultRun addObjectsFromArray:privateRun];
        [resultRun addObjectsFromArray:fbFriendsRun];
    }
    
    [self.director tokenArrayReady:resultRun FromBuilder:self];
}


- (BOOL) downloadAudioAndImageForDiafilm:(Diafilm *) df
{
    for (PFObject *pfDiafilm in results)
    {
        if ( [df.uniqStrToken isEqualToString:[pfDiafilm  objectForKey:@"token"]] )
        {
            PFFile *audioFile = [pfDiafilm objectForKey:@"audio"];
            PFFile *thumbFile = [pfDiafilm objectForKey:@"thumb"];
            
            Diafilm * newdf = [DiafilmFSSaver buildDiafilmInAlbumPath:self.albumDirectory 
                                                            WithToken:[pfDiafilm objectForKey:@"token"] 
                                                            ThumbData:[thumbFile getData] 
                                                            AudioData:[audioFile getData]];
            
            if (!newdf)
                return NO;
            
            df.thumbFile = newdf.thumbFile;
            df.audioFile = newdf.audioFile;
            
            return YES;
        }
    }
    
    return NO;
    NSAssert(0, @"token which is not present in Parse Downloader internal state was requested!");
}


- (void) downloadDiafilmBasedOnToken:(NSString *) diafilmToken
{
    for (PFObject *pfDiafilm in results)
    {
        if ( [diafilmToken isEqualToString:[pfDiafilm  objectForKey:@"token"]] )
        {
            Diafilm * df = [self createDiafilmFromParseDiafilm:pfDiafilm];
            [self.director diafilmDownloaded:df ByBuilder:self];
            return;
        }
    }
    
    NSAssert(0, @"token which is not present in Parse Downloader internal state was requested!");
}

- (RegisteredUser *) createRegisteredUserFromPFObject: (PFObject *) pfRow
{
    AllUsers * au =  [AllUsers singleton];    
    RegisteredUser * reguser = nil;
    
    NSString *useridstr= [pfRow  objectForKey:@"userid"];
    NSNumber *userid   = [[NSNumber alloc] initWithLongLong:[useridstr longLongValue]];
    NSString *username = [pfRow  objectForKey:@"username"];
    
    NSData *userPicData = nil;
    
    // if user already exist, skip fetching fb userpic
    if (![au doesUserExistWithFBId: userid])
        userPicData = [HelperFunctions fetchFBUserPicFromUserId:useridstr];
    
    // if user already exists, it will return user from database
    reguser = [au addUserWithFBId:userid Name:username UserPic:userPicData];

    return reguser;
}


- (Diafilm *) createDiafilmFromParseDiafilm:(PFObject *) pfDiafilm
{    
    Diafilm *df = [[Diafilm alloc] initWithID:[pfDiafilm objectForKey:@"token"]];
    df.owner      = [self createRegisteredUserFromPFObject:pfDiafilm];
    df.creationDate = pfDiafilm.createdAt;
    
    // check that user exists
    if (!(df.owner))
        return nil;

    return df;
}

@end
