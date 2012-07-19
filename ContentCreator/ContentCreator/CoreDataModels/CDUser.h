//
//  CDUser.h
//  ContentCreator
//
//  Created by Aashish Patel on 6/19/12.
//  Copyright (c) 2012 Mulishani LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDAlbum, CDComment, CDDiafilm;

@interface CDUser : NSManagedObject

@property (nonatomic, retain) NSNumber * fbid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * userpicPath;
@property (nonatomic, retain) CDAlbum *allUserAlbums;
@property (nonatomic, retain) CDComment *allUserComments;
@property (nonatomic, retain) NSSet *diafilms;
@end

@interface CDUser (CoreDataGeneratedAccessors)

- (void)addDiafilmsObject:(CDDiafilm *)value;
- (void)removeDiafilmsObject:(CDDiafilm *)value;
- (void)addDiafilms:(NSSet *)values;
- (void)removeDiafilms:(NSSet *)values;

@end
