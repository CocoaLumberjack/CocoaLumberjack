//
//  SwiftLogLevel.h
//  Lumberjack
//
//  Created by Florian Friedrich on 05.10.18.
//

#ifndef SwiftLogLevel_h
#define SwiftLogLevel_h

#ifndef DD_LOG_LEVEL
// #warning 'DD_LOG_LEVEL' is not defined. Using 'DDLogLevelAll' as default. Consider defining it yourself.
#define DD_LOG_LEVEL DDLogLevelAll
#endif

static const DDLogLevel DDDefaultLogLevel = DD_LOG_LEVEL;

#endif /* SwiftLogLevel_h */
