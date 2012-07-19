//
//  Diafilm.m
//  ContentCreator
//
//  Created by Boris on 3/23/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "Diafilm.h"
#import "dlLog.h"
#import "HelperFunctions.h"
#import "VideoCreator.h"


@interface Comment ()


@end

@implementation Comment

@synthesize audioFile = _audioFile;
@synthesize owner = _owner;

- (NSString *) getAudioFile
{
    // FIXME:
    return nil;
}

- (NSString *) getUsername
{
    return @"Boris Suvorov";
}

- (NSString  *) getUserid
{
    return @"664500484";
}

- (NSString *) getUserpic
{
    
    NSString * userpicDir = [HelperFunctions getUserpicDir];
    if( userpicDir == nil )
    {
        return nil;
    }
    
    NSFileManager * fm = [[NSFileManager alloc] init];
    NSError * error;
    
    NSArray * filenames = [fm contentsOfDirectoryAtPath:userpicDir error:&error];
    
    if( [filenames count] == 0 )
    {
        return nil;
    }
    
    return ((NSString *) [filenames objectAtIndex:0]);
}

@end

@interface Comments ()

@end

@implementation Comments

@synthesize comments;

- (int) commentCount
{
    return [self.comments count];
}

- (Comments *) getCommentAtIndex:(int) index
{
    if( self.comments )
    {
        return [self.comments objectAtIndex:index];
    }
    
    return nil;
}

@end



@interface Diafilm () 

@property (nonatomic) int intToken;                  // it is actually timestamp of creation, used for sorting. not used for filesystem
@property (nonatomic) NSString* uniqStrToken;     // it is token + @"_"<rand number> to avoid any collision in filesystem

@end

@implementation Diafilm

@synthesize intToken = _intToken;
@synthesize uniqStrToken = _uniqStrToken;
@synthesize audioFile = _audioFile;
@synthesize imageFile = _imageFile;
@synthesize thumbFile = _thumbFile;
@synthesize comments = _comments;
@synthesize owner = _owner;
@synthesize creationDate = _creationDate;

- (id) initWithID:(NSString *) diafilmStrToken;
{
    self = [super init];
    self.uniqStrToken = diafilmStrToken;
    self.intToken = [HelperFunctions extractIntFromToken:diafilmStrToken];

    if (self.intToken == 0)
        NSAssert(0, @"int token is zero!");
    return self;
}

- (id) initWithID:(NSString *) diafilmStrToken AudioFile:(NSString*) audioFileName ImageFile:(NSString *) imageFileName UserPicFile:(NSString *) userPicFilename;
{
    self = [super init];
    self.audioFile = audioFileName;
    self.imageFile = imageFileName;
    self.uniqStrToken = diafilmStrToken;
    self.intToken = [HelperFunctions extractIntFromToken:diafilmStrToken];

    if (self.intToken == 0)
        NSAssert(0, @"int token is zero!");
    
    return self;
}

- (id) initWithID:(NSString *) diafilmStrToken AudioFile:(NSString*) audioFileName ImageFile:(NSString *) imageFileName username:(NSString *) fbUsername
{
    self = [super init];
    self.audioFile = audioFileName;
    self.imageFile = imageFileName;
    self.uniqStrToken = diafilmStrToken;
    self.intToken = [HelperFunctions extractIntFromToken:diafilmStrToken];
    
    if (self.intToken == 0)
        NSAssert(0, @"int token is zero!");
    
    return self;
}

NSString * firstPath = @"http://graph.facebook.com/";
NSString * lastPath  = @"/picture";


- (UIImage *) getUserPic
{
    return [[UIImage alloc] initWithContentsOfFile:self.owner.userpicPath];
}

- (NSString *) getThumbNailFileName
{
    if (self.thumbFile == nil) {
        if (self.imageFile == nil) {
//            NSAssert(0, @"Missing image file and missing thumb file!");
            return nil;
        } else {
            self.thumbFile = [self.imageFile stringByReplacingOccurrencesOfString:@"image" withString:@"thumb"];
        }
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.thumbFile]) {
        dlLogInfo(@"Thumbnail is missing, creating one for image %@",self.imageFile);
        self.thumbFile = [HelperFunctions createThumbFromImageFile:self.imageFile];
    }
    
    return self.thumbFile;
}

- (NSString *)getImageFilename
{
    return self.imageFile;
}

- (UIImage *)getThumbNail
{
    dlLogDebug(@"requesting %@", [self getThumbNailFileName]);
    UIImage * fileImg = [[UIImage alloc] initWithContentsOfFile:[self getThumbNailFileName]];

    // should add code to differentiate between retina and non retina displays
    //[UIImage imageWithCGImage:fileImg.CGImage scale:2 orientation:fileImg.imageOrientation];
    return fileImg;
    
}

- (UIImage *)getImage
{
    return [[UIImage alloc] initWithContentsOfFile:self.imageFile];
}

- (NSURL *)getAudioURL
{
    if (self.audioFile == nil) {
        dlLogDebug(@"Haven't uploaded audio yet");
        return nil;
    }
    return [NSURL fileURLWithPath:self.audioFile];;
}

- (NSString *) getAudioFilename
{
    return self.audioFile;
}

- (NSString *) getUsername
{
    return self.owner.name;
}

- (NSNumber *) getUserId
{
    return self.owner.fbid;
}

- (NSString *)   getImageDate
{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    [dateFormatter setDoesRelativeDateFormatting:YES];
    NSDate * elapsedTime = self.creationDate;
    
    NSString * dateDescription = [dateFormatter stringFromDate:elapsedTime];
    
    return dateDescription;
}

- (NSString *) getVideoWithThumbnailPath
{
    return nil;
    
}


- (NSString *) getVideoWithFullSizePath
{
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)coder 
{
    [coder encodeObject:self.audioFile forKey:@"audioFile"];
    [coder encodeObject:self.imageFile forKey:@"imageFile"];
    [coder encodeObject:self.thumbFile forKey:@"thumbFile"];
}

- (void)decodeWithCoder:(NSCoder *)coder
{
    self.audioFile =   [coder decodeObjectForKey:@"audioFile"];
    self.imageFile =   [coder decodeObjectForKey:@"imageFile"];
    self.thumbFile =   [coder decodeObjectForKey:@"thumbFile"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    [self setAudioFile:[coder decodeObjectForKey:@"audioFile"]];
    [self setImageFile:[coder decodeObjectForKey:@"imageFile"]];
    [self setThumbFile:[coder decodeObjectForKey:@"thumbFile"]];
    return self;
}


// this is pure stubs, will be replaced with Core Data changes roll out
- (NSString *) getCommentAudioPathsAtIndex:(int) index
{
    return self.audioFile;
}

- (NSString *) getCommentUserPicPathAtIndex:(int) index
{
    return self.owner.userpicPath;    
}

- (BOOL) addNewAudioComment:(NSString *) pathToAudioFile
{
    dlLogDebug(@"Adding new Audio Comment");
    // FIXME - Boris' code needs to add the comments here
    return TRUE;
}

- (int) getCommentCount
{
    // FIXME:
    return 5;
}

@end
