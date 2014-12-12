//
//  lelib.h
//  lelib
//
//  Created by Petr on 27.10.13.
//  Copyright (c) 2013,2014 Logentries. All rights reserved.
//

// LE should not write to console; CocoaLumberjack will take care of this upstream if the user wants it.
#define LE_DEBUG_LOGS 0

#ifndef LE_DEBUG_LOGS
    #ifdef DEBUG
        #define LE_DEBUG_LOGS 1
    #else
        #define LE_DEBUG_LOGS 0
    #endif
#endif

#if LE_DEBUG_LOGS
#define LE_DEBUG(...)         NSLog(__VA_ARGS__)
#else
#define LE_DEBUG(...)
#endif

#import "LELog.h"
#import "lecore.h"
