//
//  main.m
//  Benchmarking
//
//  Created by Hakon Hanesand on 1/11/19.
//  Copyright © 2019 CocoaLumberjack. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PerformanceTesting.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [PerformanceTesting startPerformanceTests];
    }
    return 0;
}
