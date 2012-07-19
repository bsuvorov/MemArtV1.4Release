//
//  RegisteredUser.h
//  ContentCreator
//
//  Created by Boris on 6/17/12.
//  Copyright (c) 2012 Dearlena, inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegisteredUser : NSObject

@property (nonatomic, strong) NSString *name;           // username of the person who took the image
@property (nonatomic, strong) NSNumber *fbid;              // fb user id of the person who took the image
@property (nonatomic, strong) NSString *userpicPath;


@end

@interface AllUsers : NSObject

- (RegisteredUser *) addUserWithFBId:(NSNumber *) fbid
                                Name:(NSString *) name
                             UserPic:(NSData *) userpicData;

- (RegisteredUser *) addUserWithFBId:(NSNumber *) fbid
                                Name:(NSString *) name
                         UserPicPath:(NSString *) userpicPath;

- (BOOL) doesUserExistWithFBId:(NSNumber *) fbid;

+ (AllUsers *) singleton;

@end