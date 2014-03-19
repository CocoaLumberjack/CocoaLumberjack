//
//  DDASLLogCapture.m
//  Lumberjack
//
//  Created by Dario Ahdoot on 3/17/14.
//
//

#import "DDASLLogCapture.h"
#import "DDLog.h"

#include <asl.h>
#include <notify.h>
#include <notify_keys.h>
#include <sys/time.h>

static BOOL asynchronous;
static BOOL cancel;

@implementation DDASLLogCapture

+ (void)start:(BOOL)isAsynchronous
{
  cancel = FALSE;
  asynchronous = isAsynchronous;

  dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
  {
    [DDASLLogCapture captureAslLogs];
  });
}

+ (void)stop
{
  cancel = TRUE;
}

+ (void)configureAslQuery:(aslmsg)query
{
  // TODO: Make this confgurable based on current log level?
  const char param[] = "7";  // ASL_LEVEL_DEBUG, which is everything. We'll rely on regular DDlog log level to filter
  asl_set_query(query, ASL_KEY_LEVEL, param, ASL_QUERY_OP_LESS_EQUAL | ASL_QUERY_OP_NUMERIC);

#if !TARGET_OS_IPHONE
  int processId = [[NSProcessInfo processInfo] processIdentifier];
  char pid[16];
  sprintf(pid, "%d", processId);
  asl_set_query(query, ASL_KEY_PID, pid, ASL_QUERY_OP_EQUAL | ASL_QUERY_OP_NUMERIC);
#endif
}

+ (void)aslMessageRecieved:(aslmsg)msg
{
//  NSString * sender = [NSString stringWithCString:asl_get(msg, ASL_KEY_SENDER) encoding:NSUTF8StringEncoding];
  NSString * message = [NSString stringWithCString:asl_get(msg, ASL_KEY_MSG) encoding:NSUTF8StringEncoding];
  NSString * level = [NSString stringWithCString:asl_get(msg, ASL_KEY_LEVEL) encoding:NSUTF8StringEncoding];
  NSString * secondsStr = [NSString stringWithCString:asl_get(msg, ASL_KEY_TIME) encoding:NSUTF8StringEncoding];
  NSString * nanoStr = [NSString stringWithCString:asl_get(msg, ASL_KEY_TIME_NSEC) encoding:NSUTF8StringEncoding];

  NSTimeInterval seconds = [secondsStr doubleValue];
  NSTimeInterval nanoSeconds = [nanoStr doubleValue];
  NSTimeInterval totalSeconds = seconds + (nanoSeconds / 1e9);

  NSDate * timeStamp = [NSDate dateWithTimeIntervalSince1970:totalSeconds];

  int logLevel = 0;
  switch([level intValue])
  {
    // TODO: Not too sure about these mappings
    case ASL_LEVEL_EMERG   : logLevel = LOG_FLAG_ERROR;         break;
    case ASL_LEVEL_ALERT   : logLevel = LOG_FLAG_ERROR;         break;
    case ASL_LEVEL_CRIT    : logLevel = LOG_FLAG_WARN;          break;
    case ASL_LEVEL_ERR     : logLevel = LOG_FLAG_INFO;          break;
    case ASL_LEVEL_WARNING : logLevel = LOG_FLAG_DEBUG;         break;
    case ASL_LEVEL_NOTICE  : logLevel = LOG_FLAG_DEBUG;         break;
    case ASL_LEVEL_INFO    : logLevel = LOG_FLAG_DEBUG;         break;
    case ASL_LEVEL_DEBUG   : logLevel = LOG_FLAG_DEBUG;         break;
    default                : logLevel = LOG_FLAG_VERBOSE;       break;
  }

  // TODO: Need to set context/tag here so these can be filtered by the ASL logger. Not familiar enough
  // with Lumberjack to do this properly.
  DDLogMessage * logMessage = [[DDLogMessage alloc]initWithLogMsg:message
                                                            level:logLevel
                                                             flag:logLevel // <-- TODO: Need to get ddLogLevel here. Not sure now.
                                                          context:0
                                                             file:0
                                                         function:0
                                                             line:0
                                                              tag:nil
                                                          options:0
                                                        timestamp:timeStamp];

  [DDLog queueLogMessage:logMessage asynchronously:asynchronous];
}

+ (void)captureAslLogs
{
  @autoreleasepool
  {
    /*
     We use ASL_KEY_MSG_ID to see each message once, but there's no
     obvious way to get the "next" ID. To bootstrap the process, we'll
     search by timestamp until we've seen a message.
     */

    struct timeval timeval = { .tv_sec = 0 };
    gettimeofday(&timeval, NULL);
    unsigned long long startTime = timeval.tv_sec;
    __block unsigned long long lastSeenID = 0;

    /*
     syslogd posts kNotifyASLDBUpdate (com.apple.system.logger.message)
     through the notify API when it saves messages to the ASL database.
     There is some coalescing - currently it is sent at most twice per
     second - but there is no documented guarantee about this. In any
     case, there may be multiple messages per notification.

     Notify notifications don't carry any payload, so we need to search
     for the messages.
     */
    int notifyToken;  // Can be used to unregister with notify_cancel().
    notify_register_dispatch(kNotifyASLDBUpdate, &notifyToken, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(int token)
    {
      // At least one message has been posted; build a search query.
      @autoreleasepool
      {
        aslmsg query = asl_new(ASL_TYPE_QUERY);
        char stringValue[64];
        if (lastSeenID > 0)
        {
          snprintf(stringValue, sizeof stringValue, "%llu", lastSeenID);
          asl_set_query(query, ASL_KEY_MSG_ID, stringValue, ASL_QUERY_OP_GREATER | ASL_QUERY_OP_NUMERIC);
        }
        else
        {
          snprintf(stringValue, sizeof stringValue, "%llu", startTime);
          asl_set_query(query, ASL_KEY_TIME, stringValue, ASL_QUERY_OP_GREATER_EQUAL | ASL_QUERY_OP_NUMERIC);
        }
        [DDASLLogCapture configureAslQuery:query];

        // Iterate over new messages.
        aslmsg msg;
        aslresponse response = asl_search(NULL, query);
        while ((msg = aslresponse_next(response)))
        {
          [DDASLLogCapture aslMessageRecieved:msg];

          // Keep track of which messages we've seen.
          lastSeenID = atoll(asl_get(msg, ASL_KEY_MSG_ID));
        }
        aslresponse_free(response);

        if(cancel)
        {
          notify_cancel(notifyToken);
          return;
        }
      }
    });
  }
}

@end