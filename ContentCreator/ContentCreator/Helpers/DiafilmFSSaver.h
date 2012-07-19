//
//  DiafilmFSSaver.h
//  ContentCreator
//
//  Created by Michael Suvorov on 6/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Diafilm.h"

@interface DiafilmFSSaver : NSObject

+ (Diafilm *) buildDiafilmInAlbumPath:(NSString *) albumPath
                            WithToken:(NSString *) uniqfname 
                            ThumbData:(NSData *) thumbData 
                            AudioData:(NSData *) audioData;

+ (Diafilm *) buildDiafilmInAlbumPath:(NSString *) albumPath
                            WithToken:(NSString *) uniqfname 
                            ImagePath:(NSString *) tmpImagePath 
                            AudioPath:(NSString *) tmpAudioPath;

+ (BOOL) updateDateOfDiafilmWithToken:(int) intToken ToDate:(NSDate *) newDate;

+ ( void ) saveToCDDiafilmSet:(NSArray *) diafilms
          WithCompletionBlock:(void (^)(BOOL success)) completionBlock;


@end
