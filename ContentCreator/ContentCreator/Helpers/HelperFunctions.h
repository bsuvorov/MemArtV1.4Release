//
//  HelperFunctions.h
//  ContentCreator
//
//  Created by Boris on 4/12/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HelperFunctions : NSObject

+ (NSString *) copyFile:(NSString*)path ToFolder: (NSString*) folder WithNewName:(NSString*) newName Extension:(NSString *) extension;
+ (NSData *) fetchFBUserPicFromUserId: (NSString *) userid;

+ (int) extractIntFromToken: (NSString *) token;

+ (NSString*) createThumbFromImageFile:(NSString*) imageFile;
+ (UIImage *) getSquareThumbFromImage:(UIImage *) image;
+ (UIImage *) scaleImage:(UIImage*) image FitInDestSize: (CGSize) targetSize;
+ (UIImage *) cropImage:(UIImage*) image WithRect:(CGRect)rect;

+ (void) subscribeToChannelsOfNewFriends: (NSArray *) newFriends WithoutResubscribingToOldFriends:(NSArray *) oldFriends;
+ (void) unsubscribeFromChannelOfRemovedFriends: (NSArray *) newFriends WithoutResubscribingToOldFriends:(NSArray *) oldFriends;



+ (void) unsubscribeFromAllChannels;
+ (void) subscribeToChannels;

+ (NSString *) getWallDir;
+ (NSString *) getUserpicDir;
+ (NSString *) getDemoDir;

+ (NSString *) generateTimeStampRand;

@end
