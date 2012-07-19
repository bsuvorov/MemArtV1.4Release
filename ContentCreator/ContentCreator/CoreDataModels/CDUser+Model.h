//
//  CDUser+Model.h
//  ContentCreator
//
//  Created by Boris on 6/17/12.
//  Copyright (c) 2012 Dearlena, Inc. All rights reserved.
//

#import "CDUser.h"
#import "RegisteredUser.h"

@interface CDUser (Model)

+ (RegisteredUser *) createRegisteredUserFromCDUser:(CDUser *) cduser
                             inManagedObjectContext:(NSManagedObjectContext *) context;

+ (CDUser *) createCDUserFromModelUser:(RegisteredUser *) modelUser
                inManagedObjectContext:(NSManagedObjectContext *) context;



@end
