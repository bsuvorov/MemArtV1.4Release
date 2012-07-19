//
//  CDCleaner.h
//  MemArt
//
//  Created by Boris Suvorov on 6/27/12.
//  Copyright (c) 2012 Dearlena inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CDCleaner : NSObject

+ (void) cleanupDatabaseWithCompletionBlock:(void (^)(BOOL success)) completionBlock;
+ (void) removeEverythingButAnonymousUserPostsWithCompletionBlock:(void (^)(BOOL success)) completionBlock;
@end
