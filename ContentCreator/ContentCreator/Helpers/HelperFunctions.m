//
//  HelperFunctions.m
//  ContentCreator
//
//  Created by Boris on 4/12/12.
//  Copyright (c) 2012 DearLena. All rights reserved.
//

#import "HelperFunctions.h"
#import "globalDefines.h"
#import <Parse/Parse.h>
#import "UserData.h"
#include <AVFoundation/AVFoundation.h>
#include <AVFoundation/AVAsset.h>
#import "dlLog.h"

#define DEBUG_HELPER 1

@implementation HelperFunctions

+ (NSString *) copyFile:(NSString*)path ToFolder: (NSString*) folder WithNewName:(NSString*) newName Extension:(NSString *) extension
{
    NSError *error;
    NSString *newFileName = [newName stringByAppendingPathExtension:extension];    
    NSString *newFilePath = [folder stringByAppendingPathComponent:newFileName]; 
    [[NSFileManager defaultManager] copyItemAtPath:path toPath: newFilePath error: &error];
    if (error) {
        dlLogCrit(@"Failed to copy over!\n");
    }
    
    return newFilePath;
}

+ (NSData *) fetchFBUserPicFromUserId: (NSString *) userid
{
    NSURL *userPicServerPath    = [self getFBUserPicImage:userid];
    NSData *userPicData = [NSData dataWithContentsOfURL:userPicServerPath];
    return userPicData;
}

+ (NSString*) createThumbFromImageFile:(NSString*) imageFile
{
    NSString *thumbString = [imageFile stringByReplacingOccurrencesOfString:@"image" withString:@"thumb"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:imageFile];
    UIImage *thumb = [self getSquareThumbFromImage:image];
    [UIImageJPEGRepresentation(thumb, 0.6) writeToFile:thumbString atomically:YES];
    
    return thumbString;
}

+ (UIImage *) getSquareThumbFromImage:(UIImage *) image
{
    UIImage *resultThumb = nil;
        
    float cgImageWidth  = CGImageGetWidth(image.CGImage);
    float cgImageHeight = CGImageGetHeight(image.CGImage);
    
    if (DEBUG_HELPER)
        dlLogDebug(@"width=%f, height =%f", cgImageWidth, cgImageHeight);

    
    CGRect cropSquare = (cgImageWidth > cgImageHeight) 
    ? CGRectMake(cgImageWidth/2 - cgImageHeight/2, 0, cgImageHeight, cgImageHeight)
    : CGRectMake(0, cgImageHeight/2 - cgImageWidth/2, cgImageWidth, cgImageWidth);
    
    UIImage * croppedImage = [HelperFunctions cropImage:image WithRect:cropSquare];
    CGSize destSize = CGSizeMake(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT);
    UIGraphicsBeginImageContext(destSize);
    [croppedImage drawInRect:CGRectMake(0, 0, destSize.width, destSize.height)];
    
    resultThumb = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultThumb;
}

+ (UIImage *) scaleImage:(UIImage*) image FitInDestSize: (CGSize) targetSize
{
    UIImage * resultScaledImage = nil;
    CGFloat longerSide = (image.size.height > image.size.width) ? image.size.height : image.size.width;
    CGFloat tagetLongerSide = (targetSize.height > targetSize.width) ? targetSize.height : targetSize.width;
    
    CGFloat scalingFactor = tagetLongerSide / longerSide;

    dlLogDebug(@"longerSide of image = %f, height=%f, width=%f\n", longerSide, image.size.height, image.size.width);
    dlLogDebug(@"longerSide of target rect = %f, height=%f, width=%f\n", tagetLongerSide, targetSize.height, targetSize.width);
    
    if (scalingFactor >= 1.0)
        return image;

    CGSize destSize;
    
    if (image.size.height < image.size.width)
        destSize = CGSizeMake(scalingFactor * targetSize.width, scalingFactor * targetSize.height);
    else 
        destSize = CGSizeMake(scalingFactor * targetSize.height, scalingFactor * targetSize.width);

    
    UIGraphicsBeginImageContext(destSize);
    [image drawInRect:CGRectMake(0, 0, destSize.width, destSize.height)];
    resultScaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return  resultScaledImage;
}

+ (int) extractIntFromToken: (NSString *) token
{
    NSRange range = [token rangeOfString:@"_"];
    
    return [[token substringToIndex:range.location] intValue];
}

+ (NSURL *) getFBUserPicImage:(NSString *) userid
{
    if (userid == nil)
        return nil;
    
    NSString * firstPath = @"http://graph.facebook.com/";
    NSString * lastPath  = @"/picture";
    
    NSString *fbUserPicPath = [[firstPath stringByAppendingString:userid] stringByAppendingString:lastPath];
    NSURL *fbUserPicURL = [[NSURL alloc] initWithString:fbUserPicPath];
    return fbUserPicURL;
}

+ (UIImage *)cropImage:(UIImage *) image WithRect:(CGRect)rect
{
    dlLogDebug(@"Cropping image with rect in origin.x=%f, origin.y=%f, width=%f, height=%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    dlLogDebug(@"CGImage width=%zu, height=%zu", CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    [result CGImage];
    return result;
}

/*
+ (void) publishToFacebook: (NSString *) videoFilename
{
    NSArray* permissions = [[NSArray alloc] initWithObjects:
                            @"publish_stream", nil];
    
    [PF_Facebook authorize: delegate:self];
    
    return;
}
*/


+ (void) subscribeToChannelsOfNewFriends: (NSArray *) newFriends 
        WithoutResubscribingToOldFriends: (NSArray *) oldFriends
{
    NSSet * oldFriendsSet = [[NSSet alloc] initWithArray:oldFriends];

    for (NSString * friend in newFriends)
    {
        if (![oldFriendsSet containsObject:friend]) 
        {
            NSString *chan = [NSString stringWithFormat:@"channel_%@", friend];
            dlLogInfo(@"Subscribe to %@", chan);
            [PFPush subscribeToChannelInBackground:chan block:^(BOOL succeeded, NSError *error)
            {
                if (!succeeded)
                    dlLogDebug(@"Failed to subscribe to %@, error %@", chan, error);
            }];
        }
    }
}

+ (void) unsubscribeFromChannelOfRemovedFriends: (NSArray *) newFriends
               WithoutResubscribingToOldFriends: (NSArray *) oldFriends
{
    NSSet * newFriendsSet = [[NSSet alloc] initWithArray:newFriends];
    
    for (NSString * friend in oldFriends)
    {
        if (![newFriendsSet containsObject:friend]) 
        {
            NSString *chan = [NSString stringWithFormat:@"channel_%@", friend];            
            dlLogInfo(@"Unsubscribe from %@", chan);
            [PFPush unsubscribeFromChannelInBackground:chan block:^(BOOL succeeded, NSError *error) 
            {
                if (!succeeded)
                    dlLogDebug(@"Failed to subscribe to %@, error %@", chan, error);
            }];            
        }
    }
}

+ (void) subscribeToChannelsInArray: (NSArray *) friendsIdsArray
{
    NSError *err;
    
    // Subscribe to friends 
    for (NSString *friend in friendsIdsArray) 
    {
        NSString *chan = [NSString stringWithFormat:@"channel_%@", friend];
        dlLogDebug(@"Subscribe to %@", chan);
        [PFPush subscribeToChannelInBackground:chan block:^(BOOL succeeded, NSError *error)
        {
            if (!succeeded)
                dlLogWarn(@"Failed to subscribe to %@, error %@", chan, err);
        }];
        
    }
}

// subscribe to push Notifications stuff
+ (void) subscribeToChannels
{
    UserData * ud = [UserData singleton];
    [self subscribeToChannelsInArray:ud.friendsIds];
}

// Push Notifications unsubscribe
+ (void) unsubscribeFromAllChannels
{
    [PFPush getSubscribedChannelsInBackgroundWithBlock:^(NSSet *channels, NSError *error) 
    {
        NSError *err;
        // Unsubscribe from all channels
        for (NSString *chan in channels) 
        {
            dlLogInfo(@"Unsubscribe from %@", chan);
            [PFPush unsubscribeFromChannelInBackground:chan block:^(BOOL succeeded, NSError *error) 
            {
                if (!succeeded)
                    dlLogWarn(@"Failed to subscribe to %@, error %@", chan, err);
            }];
            
        }
    }];    
}

+ (NSString *) getWallDir
{
    NSString * documentsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString * wallDir = [documentsPath stringByAppendingPathComponent:WALL];
    
    if( [fm fileExistsAtPath:wallDir] )
    {
        return wallDir;
    }
    
    return nil;
}

+ (NSString *) getUserpicDir
{
    NSString * documentsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString * wallDir = [documentsPath stringByAppendingPathComponent:USERPICPATH];
    
    if( [fm fileExistsAtPath:wallDir] )
    {
        return wallDir;
    }
    
    return nil;
}

+ (NSString *) getDemoDir
{
    NSString * documentsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString * wallDir = [documentsPath stringByAppendingPathComponent:DEMOALBUMNAME];
    
    if( [fm fileExistsAtPath:wallDir] )
    {
        return wallDir;
    }
    
    return nil;
}

+ (NSString *) generateTimeStampRand
{
    NSNumber *rand      = [[NSNumber alloc] initWithInt:arc4random() % 100000];
    NSNumber *timestamp = [NSNumber numberWithInteger: [[NSDate date] timeIntervalSince1970]];
    NSString *uniqfname = [[NSString alloc] initWithFormat:@"%@_%@", [timestamp stringValue], [rand stringValue]];    
    return uniqfname;
}

@end
