//
//  globalDefines.h
//  ContentCreator
//
//  Created by Aashish Patel on 5/15/12.
//  Copyright (c) 2012 Dearlena Inc. All rights reserved.
//

#ifndef ContentCreator_globalDefines_h
#define ContentCreator_globalDefines_h

static const NSTimeInterval MAX_RECORDING_LENGTH_SECONDS = 20.0;
static const NSTimeInterval AUDIO_RECORDING_LENGTH_CONSIDERED_VALID = 0.5;

#define FB_ME_GRAPH_PATH @"me"
#define FB_ME_REQUEST_STRING @"https://graph.facebook.com/me"
#define FB_FRIENDS_GRAPH_PATH @"me/friends"
#define FB_VIDEO_GRAPH_PATH @"me/videos"
#define FB_VIDEO_REQUEST_STRING @"https://graph.facebook.com/me/videos"
#define FB_FRIENDS_REQUEST_STRING @"https://graph.facebook.com/me/friends"

#define USER_DEFAULT_COUNTDOWN_VALUE_KEY @"countDownValue"

#define THUMBNAIL_WIDTH  600
#define THUMBNAIL_HEIGHT 600

#define MAX_IMAGE_WIDTH  2048
#define MAX_IMAGE_HEIGHT 1536

#define UICOLOR_MEMART [UIColor colorWithRed:0.97 green:0.68 blue:0.0 alpha:1]

#define FIRST_EVER_LOAD_ALBUM_SIZE_ON 2
#define DEFAULT_ALBUM_SIZE_ON_STARTUP 15
#define DEFAULT_ALBUM_NEXT_FETCH_SIZE 6

#define DEMOALBUMNAME @"public"
#define DEMOUSERNAME @""
#define DEMOUSERNUMBERSTR @"1"
#define DEMOUSERNUM 1
#define PATH_VIDEO @"wall"
#define WALL @"wall"
#define USERPICPATH @"userpics"

#define MAX_NUMBER_OF_DIAFILMS_IN_CD 50

#define MOVIE_FPS 1

#define DF_PRIVACY_PRIVATE 0
#define DF_PRIVACY_FB 1
#define DF_PRIVACY_PUBLIC 2
#define DF_PRIVACY_PUBLIC_APPROVED 3



#endif
