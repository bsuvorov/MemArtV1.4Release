//
//  VideoCreator.h
//  ContentCreator
//
//  Created by Aashish Patel on 6/4/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VideoCreatorProtocols <NSObject>
- (void) videoCreationDone;
- (void) videoCreationFailed;
- (void) videoCreationPercentComplete:(float) percent;
@end

@interface VideoCreator : NSObject

- (void) setDelegate:(id) thisDelegate;
- (void) createVideoWithImageFile:(NSString *) imageFilename audioFile:(NSString *) audioFilename outputPath:(NSString *) outputPath;
- (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)image;

@property (nonatomic, weak) id <VideoCreatorProtocols> videoCreationDelegate;

@end
