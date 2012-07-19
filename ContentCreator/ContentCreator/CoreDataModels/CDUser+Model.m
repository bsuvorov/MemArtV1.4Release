//
//  CDUser+Model.m
//  ContentCreator
//
//  Created by Boris on 6/17/12.
//  Copyright (c) 2012 Dearlena, Inc. All rights reserved.
//

#import "CDUser+Model.h"
#import "dlLog.h"

@implementation CDUser (Model)


+ (RegisteredUser *) createRegisteredUserFromCDUser:(CDUser *) cduser
               inManagedObjectContext:(NSManagedObjectContext *) context
{
    RegisteredUser * reguser = [[RegisteredUser alloc] init];
    reguser.fbid = cduser.fbid;
    reguser.name = cduser.name;
    reguser.userpicPath = cduser.userpicPath;
    return reguser;
}

+ (CDUser *) createCDUserFromModelUser:(RegisteredUser *) modelUser
inManagedObjectContext:(NSManagedObjectContext *) context
{
    CDUser *cduser = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CDUser"];
    
    request.predicate = [NSPredicate predicateWithFormat:@"fbid = %llu", modelUser.fbid.longLongValue];
    request.sortDescriptors = nil;
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || (matches.count > 1)) {
        NSAssert(0, @"Error in %s", __FUNCTION__);        
    } else if (matches.count == 0) {
        cduser = [NSEntityDescription insertNewObjectForEntityForName:@"CDUser" inManagedObjectContext:context];
        cduser.fbid = modelUser.fbid;
        cduser.name = modelUser.name;
        cduser.userpicPath = modelUser.userpicPath;
    } else if (matches.count == 1) {
        cduser = [matches lastObject];
        dlLogDebug(@"%s found CD User already in CD with name %@! Check models first, prior to querring Core Data", __FUNCTION__, cduser.name);
    }
    
    return cduser;
}


@end
