//
//  CDCleaner.m
//  MemArt
//
//  Created by Boris Suvorov on 6/27/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "CDCleaner.h"
#import "UserData.h"
#import "CDDiafilm+Model.h"
#import "dlLog.h"
#import "globalDefines.h"

@implementation CDCleaner
          
+ (void) removeEverythingButAnonymousUserPostsWithCompletionBlock:(void (^)(BOOL success)) completionBlock
{
    UIManagedDocument *appDoc = [[UserData singleton] appCDDocument];
    NSManagedObjectContext * backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = appDoc.managedObjectContext;
    
    [backgroundContext performBlock:^{
        NSArray * matches = [[NSArray alloc] init];
        NSError * error = nil;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CDDiafilm"];
        request.predicate = [NSPredicate predicateWithFormat:@"whoTook.fbid != 0"];
        
        matches = [backgroundContext executeFetchRequest:request error:&error];
        
        if (!matches) {
            NSAssert(0, @"Error in %s", __FUNCTION__);
        }    
        
        NSFileManager * fm = [[NSFileManager alloc] init];
        for (CDDiafilm * cddf in matches)
        {
            [fm removeItemAtPath:cddf.thumbPath error:&error];
            [fm removeItemAtPath:cddf.imagePath error:&error];
            [fm removeItemAtPath:cddf.audioPath error:&error];
            
            [backgroundContext deleteObject:cddf];
        }
        
        [backgroundContext save:&error];
        if (error)
            dlLogError(@"Failed to save %@", error);
        
        [appDoc.managedObjectContext performBlock:^{
            NSError *parentError = nil;
            [appDoc.managedObjectContext save:&parentError];
            
            [appDoc saveToURL:appDoc.fileURL forSaveOperation:UIDocumentSaveForOverwriting
            completionHandler:^(BOOL success)
             {
                 completionBlock(success);
             }];
        }];
    }];
}

+ (void) cleanupDatabaseWithCompletionBlock:(void (^)(BOOL success)) completionBlock
{
    UIManagedDocument *appDoc = [[UserData singleton] appCDDocument];
    NSManagedObjectContext * backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = appDoc.managedObjectContext;
    
    [backgroundContext performBlock:^{
        NSArray * matches = [[NSArray alloc] init];
        NSError * error = nil;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CDDiafilm"];
        request.predicate = nil;
        
        // delete after next X
        request.fetchOffset = MAX_NUMBER_OF_DIAFILMS_IN_CD;
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
        request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                
        matches = [backgroundContext executeFetchRequest:request error:&error];
        
        if (!matches) {
            NSAssert(0, @"Error in %s", __FUNCTION__);
        }    

        NSFileManager * fm = [[NSFileManager alloc] init];
        for (CDDiafilm * cddf in matches)
        {
            [fm removeItemAtPath:cddf.thumbPath error:&error];
            [fm removeItemAtPath:cddf.imagePath error:&error];
            [fm removeItemAtPath:cddf.audioPath error:&error];
            
            [backgroundContext deleteObject:cddf];
        }

        [backgroundContext save:&error];
        if (error)
            dlLogError(@"Failed to save %@", error);
        
        [appDoc.managedObjectContext performBlock:^{
            NSError *parentError = nil;
            [appDoc.managedObjectContext save:&parentError];
            
            [appDoc saveToURL:appDoc.fileURL forSaveOperation:UIDocumentSaveForOverwriting
            completionHandler:^(BOOL success)
             {
                 completionBlock(success);
             }];
        }];
    }];
    
}

@end
