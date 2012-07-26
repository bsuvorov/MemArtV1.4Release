//
//  RegisteredUser.m
//  ContentCreator
//
//  Created by Boris on 6/17/12.
//  Copyright (c) 2012 Dearlena, inc. All rights reserved.
//

#import "RegisteredUser.h"
#import "UserData.h"
#import "CDUser+Model.h"

@implementation RegisteredUser


@synthesize name = _name;
@synthesize fbid = _fbid;
@synthesize userpicPath = _userpicPath;


- (id) initWithFBId:(NSNumber *) fbid
               Name:(NSString *) name
        UserPicPath:(NSString *) userpicPath
{
    self = [super init];
    if (self) {
        self.fbid = fbid;
        self.name = name;
        self.userpicPath = userpicPath;
    }
    
    return self;
}

@end


static AllUsers * allUsersModel = nil;

@interface AllUsers ()
@property (nonatomic, strong) NSMutableDictionary *userset;
@property (nonatomic, strong) NSString *pathToUserPics;

@end

@implementation AllUsers : NSObject

@synthesize userset = _userset;
@synthesize pathToUserPics = _pathToUserPics;

- (id)init
{
    self = [super init];
    if (self) {
        
        NSString * documentsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        self.pathToUserPics = [documentsPath stringByAppendingPathComponent:@"userpics"];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.pathToUserPics withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return self;
}

- (NSMutableDictionary *) userset
{
    if (_userset == nil) _userset = [[NSMutableDictionary alloc] init];
    
    return _userset;
}

- (RegisteredUser *) addUserWithFBId:(NSNumber *) fbid
                                Name:(NSString *) name
                         UserPicPath:(NSString *) userpicPath
{
    RegisteredUser *reguser = [self.userset objectForKey:fbid];
    if (reguser != nil)
        return  reguser;
    
    reguser = [[RegisteredUser alloc] initWithFBId: fbid Name:name UserPicPath: userpicPath];
    
    [self.userset setObject:reguser forKey:fbid];
    
    return reguser;
}


- (RegisteredUser *) addUserWithFBId:(NSNumber *) fbid
                                Name:(NSString *) name
                             UserPic:(NSData *) userpicData
{

    RegisteredUser *reguser = [self.userset objectForKey:fbid];
    if (reguser != nil)
        return  reguser;
    
    
    NSString *userPicFilePath   = [self.pathToUserPics stringByAppendingFormat:@"/userpic_%@.jpg", fbid];
    [userpicData    writeToFile:userPicFilePath atomically:YES];            
    
    reguser = [[RegisteredUser alloc] initWithFBId: fbid Name:name UserPicPath: userPicFilePath];

    [self.userset setObject:reguser forKey:fbid];
        
    return reguser;
}

- (BOOL) doesUserExistWithFBId:(NSNumber *) fbid
{
    return ([self.userset objectForKey:fbid] != nil) ? YES : NO;
}

+ (AllUsers *) singleton
{
    @synchronized(self) {
        if (allUsersModel == nil) {
            allUsersModel = [[self alloc] init];
        }
    }
    return allUsersModel;
}
@end