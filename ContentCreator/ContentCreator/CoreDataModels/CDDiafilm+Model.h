//
//  CDDiafilm+Model.h
//  ContentCreator
//
//  Created by Boris on 6/17/12.
//  Copyright (c) 2012 Dearlena, Inc. All rights reserved.
//

#import "CDDiafilm.h"
#import "Diafilm.h"

@interface CDDiafilm (Model)


+ (BOOL) updateCDDiafilmDateTo:(NSDate *) date 
                   ForIntToken:(int) intToken
        inManagedObjectContext:(NSManagedObjectContext *) context;

+ (Diafilm *) createModelDiafilmFromCDDiafilm:(CDDiafilm *) cdDiafilm
                             inManagedObjectContext:(NSManagedObjectContext *) context;

+ (CDDiafilm *) createCDDiafilmFromModelDiafilm:(Diafilm *) modelDiafilm
                inManagedObjectContext:(NSManagedObjectContext *) context;

@end
