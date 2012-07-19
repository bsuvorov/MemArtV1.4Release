//
//  CDDiafilm.h
//  ContentCreator
//
//  Created by Boris on 6/13/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDAlbum, CDComment, CDUser;

@interface CDDiafilm : NSManagedObject

@property (nonatomic, retain) NSString * audioPath;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSString * imagePath;
@property (nonatomic, retain) NSNumber * intToken;
@property (nonatomic, retain) NSString * strToken;
@property (nonatomic, retain) NSString * thumbPath;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) CDUser *whoTook;
@property (nonatomic, retain) CDAlbum *whichAlbum;
@end

@interface CDDiafilm (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(CDComment *)value;
- (void)removeCommentsObject:(CDComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end
