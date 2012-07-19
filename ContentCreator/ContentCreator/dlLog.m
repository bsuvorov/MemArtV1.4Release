/*
 
 dlLog.m
 
 Copyright 2012 Dearlena Inc
 
 */

#import "dlLog.h"

static dlLogLevel g_dlLogLevel = dlLogLevelInfo;

void dlLogSetLogLevel(dlLogLevel level) {
  g_dlLogLevel = level;
}

void _dlLogCrit(NSString *format, ...) {
  if (g_dlLogLevel < dlLogLevelCrit) return;
  va_list ap;
  va_start(ap, format);
  NSLogv(format, ap);
  va_end(ap);
}

void _dlLogError(NSString *format, ...) {
  if (g_dlLogLevel < dlLogLevelError) return;
  va_list ap;
  va_start(ap, format);
  NSLogv(format, ap);
  va_end(ap);
}

void _dlLogWarn(NSString *format, ...) {
  if (g_dlLogLevel < dlLogLevelWarn) return;
  va_list ap;
  va_start(ap, format);
  NSLogv(format, ap);
  va_end(ap);
}

void _dlLogInfo(NSString *format, ...) {
  if (g_dlLogLevel < dlLogLevelInfo) return;
  va_list ap;
  va_start(ap, format);
  NSLogv(format, ap);
  va_end(ap);
}

void _dlLogDebug(NSString *format, ...) {
  if (g_dlLogLevel < dlLogLevelDebug) return;
  va_list ap;
  va_start(ap, format);
  NSLogv(format, ap);
  va_end(ap);
}
