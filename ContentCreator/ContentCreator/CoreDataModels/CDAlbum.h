//
//  CDAlbum.h
//  ContentCreator
//
//  Created by Boris on 6/13/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDDiafilm, CDUser;

@interface CDAlbum : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *localDiafilms;
@property (nonatomic, retain) CDUser *owner;
@end

@interface CDAlbum (CoreDataGeneratedAccessors)

- (void)addLocalDiafilmsObject:(CDDiafilm *)value;
- (void)removeLocalDiafilmsObject:(CDDiafilm *)value;
- (void)addLocalDiafilms:(NSSet *)values;
- (void)removeLocalDiafilms:(NSSet *)values;

@end
