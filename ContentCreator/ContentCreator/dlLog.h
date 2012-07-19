/*

 dlLog.h

 Copyright 2012 Dearlena Inc
 
*/

#import <Foundation/Foundation.h>

typedef enum {
  dlLogLevelNone  = 0,
  dlLogLevelCrit  = 10,
  dlLogLevelError = 20,
  dlLogLevelWarn  = 30,
  dlLogLevelInfo  = 40,
  dlLogLevelDebug = 50
} dlLogLevel;

void dlLogSetLogLevel(dlLogLevel level);

// The actual function name has an underscore prefix, just so we can
// hijack dlLog* with other functions for testing, by defining
// preprocessor macros

void _dlLogCrit(NSString *format, ...);
void _dlLogError(NSString *format, ...);
void _dlLogWarn(NSString *format, ...);
void _dlLogInfo(NSString *format, ...);
void _dlLogDebug(NSString *format, ...);

#ifndef dlLogCrit
#define dlLogCrit(...) _dlLogCrit(__VA_ARGS__)
#endif

#ifndef dlLogError
#define dlLogError(...) _dlLogError(__VA_ARGS__)
#endif

#ifndef dlLogWarn
#define dlLogWarn(...) _dlLogWarn(__VA_ARGS__)
#endif

#ifndef dlLogInfo
#define dlLogInfo(...) _dlLogInfo(__VA_ARGS__)
#endif

#ifndef dlLogDebug
#define dlLogDebug(...) _dlLogDebug(__VA_ARGS__)
#endif
