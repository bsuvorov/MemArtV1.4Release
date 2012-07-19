//
//  DiafilmFSSaver.m
//  ContentCreator
//
//  Created by Boris Suvorov on 6/21/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "DiafilmFSSaver.h"
#import "UserData.h"
#import "HelperFunctions.h"
#import "dlLog.h"
#import "CDDiafilm+Model.h"


@implementation DiafilmFSSaver

+ (NSString *) createPathForImage:(NSString *) pathToTmpImage
                      InAlbumPath:(NSString *) albumPath
                        WithToken:(NSString *) token
{
    NSString *imageName      = [@"image_"   stringByAppendingString:token];
    NSString *localImagePath = [HelperFunctions copyFile:pathToTmpImage ToFolder:albumPath WithNewName:imageName Extension:@"jpg"];
    return localImagePath;
}

+ (NSString *) createPathForAudio:(NSString *) pathToTmpAudio
                      InAlbumPath:(NSString *) albumPath
                        WithToken:(NSString *) token
{
    NSString *audioName      = token;
    NSString *localImagePath = [HelperFunctions copyFile:pathToTmpAudio ToFolder:albumPath WithNewName:audioName Extension:@"caf"];
    return localImagePath;
}


+ (NSString *) saveAudioData:(NSData *) audioData
                 inAlbumPath:(NSString *) albumPath
              ToFileForToken:(NSString *) token
{
    if (!audioData)
    {
        dlLogWarn(@"Failed to download audio file from server for token %@\n", token);
        return nil;
    }
    
    NSString *audioFilePath = [albumPath stringByAppendingFormat:@"/%@.caf", token];
    [audioData writeToFile:audioFilePath atomically:YES];
    return audioFilePath;
}

+ (NSString *) saveThumbData:(NSData *) thumbData 
                 inAlbumPath:(NSString *) albumPath 
              ToFileForToken:(NSString *) token
{
    if (!thumbData)
    {
        dlLogWarn(@"Failed to download thumb file from server for token %@\n", token);
        return nil;
    }
    
    NSString *thumbFilePath = [albumPath stringByAppendingFormat:@"/thumb_%@.jpg", token];
    [thumbData writeToFile:thumbFilePath atomically:YES];
    return thumbFilePath;
}


+ (Diafilm *) buildDiafilmInAlbumPath:(NSString *) albumPath
                            WithToken:(NSString *) uniqfname 
                            ImagePath:(NSString *) tmpImagePath 
                            AudioPath:(NSString *) tmpAudioPath
{        
    NSAssert(albumPath && uniqfname && tmpImagePath && tmpAudioPath,
             @"At least one of input args is nill, %s", __FUNCTION__);
    
    Diafilm *df = [[Diafilm alloc] initWithID:uniqfname];
    df.audioFile = [self createPathForAudio:tmpAudioPath InAlbumPath:albumPath WithToken:uniqfname];
    df.imageFile = [self createPathForImage:tmpImagePath InAlbumPath:albumPath WithToken:uniqfname];    
    df.thumbFile = [HelperFunctions createThumbFromImageFile:df.imageFile];
    
    if (df.audioFile == nil || df.imageFile == nil)
    {   
        dlLogCrit(@"Image or audio are missing from path");
        NSAssert(0, @"%s: Image or audio are missing from path, %@",
                 __FUNCTION__,
                 [[NSError alloc] initWithDomain:@"Album.m" code:-1 userInfo:nil]);
        return nil;
    }
    
    df.creationDate = [NSDate date];
    
    return df;
}


+ (Diafilm *) buildDiafilmInAlbumPath:(NSString *) albumPath
                            WithToken:(NSString *) uniqfname 
                            ThumbData:(NSData *) thumbData 
                            AudioData:(NSData *) audioData
{        
    NSAssert(albumPath && uniqfname && thumbData && audioData,
             @"At least one of input args is nill, %s", __FUNCTION__);
    
    Diafilm *df = [[Diafilm alloc] initWithID:uniqfname];
    
    df.audioFile = [self saveAudioData:audioData inAlbumPath:albumPath ToFileForToken:uniqfname];
    df.thumbFile = [self saveThumbData:thumbData inAlbumPath:albumPath ToFileForToken:uniqfname];

    
    if (df.audioFile == nil || df.thumbFile == nil)
    {   
        dlLogCrit(@"Image or audio are missing from path");
        NSAssert(0, @"%s: Image or audio are missing from path, %@",
                 __FUNCTION__,
                 [[NSError alloc] initWithDomain:@"Album.m" code:-1 userInfo:nil]);
        return nil;
    }
    
    return df;
}


+ ( void ) saveToCDDiafilmSet:(NSArray *) diafilms
          WithCompletionBlock:(void (^)(BOOL success)) completionBlock
{
    UIManagedDocument *appDoc = [[UserData singleton] appCDDocument];
    NSManagedObjectContext * backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = appDoc.managedObjectContext;
    
    [backgroundContext performBlockAndWait:^{
        NSError * error = nil;
        //        for (Diafilm * df in srvDownloadedDiafilms)
        for (Diafilm * df in diafilms)
            [CDDiafilm createCDDiafilmFromModelDiafilm:df 
                                inManagedObjectContext:backgroundContext];
        
        [backgroundContext save:&error];
        if (error)
            dlLogError(@"Failed to save %@", error);
        
        [appDoc.managedObjectContext performBlock:^{
            NSError *parentError = nil;
            [appDoc.managedObjectContext save:&parentError];
            
            [appDoc saveToURL:appDoc.fileURL forSaveOperation:UIDocumentSaveForOverwriting
            completionHandler:^(BOOL success)
             {
                 if (!success)
                     dlLogError(@"******FAILED TO SAVE MEM COREDATA TO FILE SYSTEM*****");
                 
                 completionBlock(success);
             }];
        }];
    }];
}

+ (BOOL) updateDateOfDiafilmWithToken:(int) intToken ToDate:(NSDate *) newDate
{
    UIManagedDocument *appDoc = [[UserData singleton] appCDDocument];
    NSManagedObjectContext * backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = appDoc.managedObjectContext;
    
    BOOL __block result = NO;
    
    [backgroundContext performBlock:^{
        NSError * error = nil;
    
        result = [CDDiafilm updateCDDiafilmDateTo:newDate ForIntToken:intToken inManagedObjectContext:backgroundContext];
        
        [backgroundContext save:&error];
        if (error) 
        {
            dlLogError(@"Failed to save %@", error);
            result = NO;
        }
        
        [appDoc.managedObjectContext performBlock:^{
            NSError *parentError = nil;
            [appDoc.managedObjectContext save:&parentError];
            
            [appDoc saveToURL:appDoc.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:nil];
        }];
    }];

    return result;
}


@end
