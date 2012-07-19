//
//  CDDiafilm+Model.m
//  ContentCreator
//
//  Created by Boris on 6/17/12.
//  Copyright (c) 2012 Dearlena, Inc. All rights reserved.
//

#import "CDDiafilm+Model.h"
#import "CDUser+Model.h"
#import "dlLog.h"

@implementation CDDiafilm (Model)

NSString * CDDiafilmEntityName =  @"CDDiafilm";

+ (NSArray *) searchForCDDiafilmByToken:(int) token
                 inManagedObjectContext:(NSManagedObjectContext *) context
{    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:CDDiafilmEntityName];
    
    request.predicate = [NSPredicate predicateWithFormat:@"intToken = %d", token];
    request.sortDescriptors = nil;
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];

    if (!matches || (matches.count > 1)) {
        NSAssert(0, @"Error in %s", __FUNCTION__);
        return nil;
    }    
    
    return matches;
}

+ (BOOL) updateCDDiafilmDateTo:(NSDate *) date 
                      ForIntToken:(int) intToken
        inManagedObjectContext:(NSManagedObjectContext *) context
{
    CDDiafilm *cdDiafilm = nil;

    NSArray *matches = [CDDiafilm searchForCDDiafilmByToken:intToken inManagedObjectContext:context];
    
    if (!matches || (matches.count > 1)) {
        NSAssert(0, @"Error in %s", __FUNCTION__);
        return NO;
    } else if (matches.count == 0) {
        return NO;
    } 
    
    // implies matches.count == 1
    cdDiafilm = [matches lastObject];
    cdDiafilm.creationDate = date;
    
    return YES;
}

+ (Diafilm *) createModelDiafilmFromCDDiafilm:(CDDiafilm *) cdDiafilm
                       inManagedObjectContext:(NSManagedObjectContext *) context
{
    Diafilm * modelDiafilm = [[Diafilm alloc] initWithID:cdDiafilm.strToken];
    
    modelDiafilm.audioFile = cdDiafilm.audioPath;
    modelDiafilm.imageFile = cdDiafilm.imagePath;
    modelDiafilm.thumbFile = cdDiafilm.thumbPath;
    modelDiafilm.comments  = nil;
    modelDiafilm.creationDate = cdDiafilm.creationDate;
    modelDiafilm.owner      = [CDUser createRegisteredUserFromCDUser:cdDiafilm.whoTook 
                                             inManagedObjectContext:context];

    return modelDiafilm;
}

+ (CDDiafilm *) createCDDiafilmFromModelDiafilm:(Diafilm *) modelDiafilm
                        inManagedObjectContext:(NSManagedObjectContext *) context
{
    CDDiafilm *cdDiafilm = nil;
    
    NSArray *matches = [CDDiafilm searchForCDDiafilmByToken:modelDiafilm.intToken inManagedObjectContext:context];
    
    if (!matches || (matches.count > 1)) {
        NSAssert(0, @"Error in %s", __FUNCTION__);
    } else if (matches.count == 0) {
        cdDiafilm = [NSEntityDescription insertNewObjectForEntityForName:CDDiafilmEntityName inManagedObjectContext:context];
        cdDiafilm.audioPath=modelDiafilm.audioFile;
        cdDiafilm.creationDate = 0;
        cdDiafilm.imagePath=modelDiafilm.imageFile;
        cdDiafilm.intToken = [[NSNumber alloc] initWithInt:modelDiafilm.intToken];
        cdDiafilm.strToken = modelDiafilm.uniqStrToken;
        cdDiafilm.thumbPath = modelDiafilm.thumbFile;
        cdDiafilm.whoTook = [CDUser createCDUserFromModelUser:modelDiafilm.owner inManagedObjectContext:context];
        cdDiafilm.creationDate = modelDiafilm.creationDate;
    } else if (matches.count == 1) {
        cdDiafilm = [matches lastObject];
        dlLogDebug(@"%s found CD Diafilm already in CD with token %@! Check models first, prior to querring Core Data", __FUNCTION__, cdDiafilm.strToken);
    }
    
    return cdDiafilm;
    
}


@end
