//
//  CDComment.h
//  ContentCreator
//
//  Created by Boris on 6/13/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDDiafilm, CDUser;

@interface CDComment : NSManagedObject

@property (nonatomic, retain) NSString * audioPath;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSString * emotionType;
@property (nonatomic, retain) CDUser *owner;
@property (nonatomic, retain) CDDiafilm *whichDiafilm;

@end
