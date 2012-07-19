//
//  VideoCreator.m
//  ContentCreator
//
//  Created by Aashish Patel on 6/4/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import "VideoCreator.h"
#import "dlLog.h"
#include <AVFoundation/AVFoundation.h>
#include <AVFoundation/AVAsset.h>
#import "globalDefines.h"

@implementation VideoCreator

@synthesize videoCreationDelegate = _videoCreationDelegate;


- (void) createVideoWithImageFile:(NSString *) imageFilename audioFile:(NSString *) audioFilename outputPath:(NSString *) outputPath
{
    // This function takes ONE static image and an audio file and generates a quicktime movie.
    // The overall function is to take the image, read the audio file and then for every track of
    // the audio file, insert a pixelbuffer containing the image
    
    
    // The video will be the size of the image
    // This is based on the assumption that only thumbnails will be called wit this function
    // FIXME: if video size is too large!
    
    UIImage * tempImage = [[UIImage alloc] initWithContentsOfFile:imageFilename];   
    // UIImage * tempImage = [UIImage imageNamed:@"test.jpg"];
    CGImageRef theImage = CGImageCreateCopy( tempImage.CGImage );
    CGSize size = CGSizeMake(CGImageGetWidth( theImage ), CGImageGetHeight( theImage ));
    
    // [UIImageJPEGRepresentation([UIImage imageWithCGImage:(theImage)], 0.6) writeToFile:[imageFilename stringByAppendingString:@".tmp"] atomically:YES];
    
    // CGSize size = CGSizeMake(CGImageGetWidth( theImage ) * 2, CGImageGetHeight( theImage ) * 2);
    
    //const char * tempFilename = [imageFilename UTF8String];
    //CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(tempFilename); 
    //CGImageRef theImage = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
    //CGSize size = CGSizeMake(CGImageGetWidth(theImage), CGImageGetHeight(theImage));
    
    NSError *error = nil;
    
    //----initialize compression engine
    
    // Initalize the AVAsset that will do the actual writing of the video file
    // It's a quick time movie that we're writing
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:outputPath]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    
    NSParameterAssert(videoWriter);
    if(error)
    {
        dlLogError(@"error = %@", [error localizedDescription]);
        [self.videoCreationDelegate videoCreationFailed];
        return;
    }
    
    
    // We're going to usre the H.264 codec with the pre-defined width and height
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
    
    
    // One of the inputs to write the video will be the image
    __strong AVAssetWriterInput *imageInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    // The other input will be audio
    __strong AVAssetWriterInput *audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:nil];
    
    /*
     NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
     */
    
    // This is the adapter between a video (imageInput) and the image we will be providing
    AVAssetWriterInputPixelBufferAdaptor *adapter = 
    [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:imageInput
                                                                     sourcePixelBufferAttributes:nil]; //sourcePixelBufferAttributesDictionary];
    
    // Now for Audio. Since the audio file already exists, we will use AVAsset to read the audio filename
    __strong AVAsset *avAudioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:audioFilename] options:nil];
    
    
    // Reading will be done with AVAssetReader
    __strong AVAssetReader *audioReader = [AVAssetReader assetReaderWithAsset:avAudioAsset error:&error];
    
    // Which track do we want to read - since we only have one, the first
    AVAssetTrack* audioTrack = [[avAudioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    // The output of the audio reading
    __strong AVAssetReaderOutput *audioReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
    
    [audioReader addOutput:audioReaderOutput];
    audioInput.expectsMediaDataInRealTime = YES;
    
    // Add inputs to the video writer
    NSParameterAssert(imageInput);
    NSParameterAssert([videoWriter canAddInput:imageInput]);
    
    if ([videoWriter canAddInput:imageInput])
        dlLogDebug(@"I can add this image input");
    else
    {
        dlLogWarn(@"i can't add this image input");
        [self.videoCreationDelegate videoCreationFailed];
        return;

    }
    [videoWriter addInput:imageInput];
    
    NSParameterAssert(audioInput);
    NSParameterAssert([videoWriter canAddInput:audioInput]);
    
    if([videoWriter canAddInput:audioInput])
        dlLogDebug(@"I can add audio input");
    else {
        dlLogWarn(@"I cannot add audio input");
    }
    
    [videoWriter addInput:audioInput];
    
    
    
    // Start writing the video
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    [audioReader startReading];
    
    
    int __block         frame = 0;
    
    CMTime audioDuration = avAudioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    int __block         maxFrames = (int) audioDurationSeconds * MOVIE_FPS;
    BOOL __block videoDone = FALSE;
    
    dlLogDebug(@"Max Frames: %d", maxFrames);
    
    // int __block         x;
    
    CVPixelBufferRef __block imageBuffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:theImage];
    if (!imageBuffer)
    {
        dlLogError(@"Error creating pixelBuffer!");
        [self.videoCreationDelegate videoCreationFailed];
        return;
    }
    
    dispatch_queue_t    dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    [audioInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:
     ^{  
         while( [imageInput isReadyForMoreMediaData] && (frame <= maxFrames) )
         {
             if(![adapter appendPixelBuffer:imageBuffer withPresentationTime:CMTimeMake(frame, MOVIE_FPS)])
             {
                 dlLogWarn(@"FAIL writing video frame");
                 [videoWriter finishWriting];
                 [self.videoCreationDelegate videoCreationFailed];
                 return;
                 break;
             } else {
                 dlLogDebug(@"Success writing frame:%d", frame);
                 [self.videoCreationDelegate videoCreationPercentComplete:((float)frame/(float)maxFrames)];
                 ++frame;
             }
         }
         if( frame > maxFrames && !videoDone)
         {
             dlLogWarn(@"Writing files frame:%d, maxFrames:%d", frame, maxFrames);
             [imageInput markAsFinished];
             // [videoWriter finishWriting];
             CVPixelBufferRelease(imageBuffer);
             [videoWriter startSessionAtSourceTime:kCMTimeZero];
             videoDone = TRUE;
         }
         if( videoDone )
         {
             while ([audioInput isReadyForMoreMediaData]) 
             {
                 CMSampleBufferRef sampleBuffer;
                 if([audioReader status] == AVAssetReaderStatusReading &&
                    (sampleBuffer = [audioReaderOutput copyNextSampleBuffer]))
                 {
                     if(sampleBuffer)
                     {
                         dlLogDebug(@"Append Audio Buffer");
                         [audioInput appendSampleBuffer:sampleBuffer];
                     }
                     CFRelease(sampleBuffer);
                 } else {
                     dlLogInfo(@"Finished making movie file!");
                     [audioInput markAsFinished];
                     switch([audioReader status])
                     {
                         case AVAssetReaderStatusCompleted:
                             [videoWriter finishWriting];
                             dispatch_sync(dispatch_get_main_queue(), ^{[self.videoCreationDelegate videoCreationDone];});
                             return;
                         default:
                             return;
                             
                     }
                 }
             }
         }       
         
         
     }
     ];
    
    
    
}

- (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)image
{

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, 
                                          320, // CGImageGetWidth(image),
                                          480, // CGImageGetHeight(image), 
                                          kCVPixelFormatType_32ARGB, 
                                          (__bridge CFDictionaryRef) options, 
                                          &pxbuffer);
    
    status=status;//Added to make the stupid compiler not show a stupid warning.
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, 
                                                 320, // CGImageGetWidth(image),
                                                 480, // CGImageGetHeight(image), 
                                                 8, 
                                                 4*320, // CGImageGetWidth(image), 
                                                 rgbColorSpace, 
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    // CGContextTranslateCTM(context, 0, CGImageGetHeight(image));
    // CGContextScaleCTM(context, 1.0, -1.0);//Flip vertically to account for different origin
    // CGContextConcatCTM(context, freeTransform);
    
    CGContextDrawImage(context, CGRectMake(0, 
                                           0, 
                                           320, // CGImageGetWidth(image), 
                                           480), // CGImageGetHeight(image)), 
                       image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void) setDelegate:(id) thisDelegate
{
    self.videoCreationDelegate = thisDelegate;
    return;
}

@end
