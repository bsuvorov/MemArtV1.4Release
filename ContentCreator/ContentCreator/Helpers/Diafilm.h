//
//  Diafilm.h
//  ContentCreator
//
//  Created by Boris on 3/23/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RegisteredUser.h"

@interface Comment : NSObject
{
}

@property (nonatomic, strong) NSString *audioFile;
@property (nonatomic, strong) RegisteredUser *owner;

- (NSString *) getAudioFile;
- (NSString *) getUsername;
- (NSString *) getUserid;
- (NSString *) getUserpic;

@end

@interface Comments : NSObject
{
}

@property (readonly, nonatomic) NSArray * comments;

- (int) commentCount;
- (Comment *) getCommentAtIndex:(int) index;


@end


@interface Diafilm : NSObject <NSCoding>
{
}

@property (readonly, nonatomic) int intToken;               // it is actually timestamp of creation, used for sorting. not used for filesystem
@property (readonly, nonatomic) NSString* uniqStrToken;     // it is token + @"_"<rand number> to avoid any collision in filesystem

@property (nonatomic, strong) NSString *audioFile;
@property (nonatomic, strong) NSString *imageFile;
@property (nonatomic, strong) NSString *thumbFile;

@property (nonatomic, strong) RegisteredUser *owner;

@property (nonatomic, strong) Comments * comments;

@property (nonatomic, strong) NSDate *creationDate;

- (id) initWithID:(NSString *) diafilmStrToken;

- (UIImage *)  getUserPic;
- (NSString *) getUsername;
- (NSNumber *) getUserId;

- (UIImage *)  getImage;

- (NSString *) getThumbNailFileName;
- (UIImage *)  getThumbNail;

- (NSURL *)    getAudioURL;
- (NSString *) getAudioFilename;

- (NSString *) getImageDate;

- (NSString *) getVideoWithThumbnailPath;
- (NSString *) getVideoWithFullSizePath;

- (NSString *) getCommentAudioPathsAtIndex:(int) index;
- (NSString *) getCommentUserPicPathAtIndex:(int) index;

- (BOOL) addNewAudioComment:(NSString *) pathToAudioFile;

- (int) getCommentCount;



@end
