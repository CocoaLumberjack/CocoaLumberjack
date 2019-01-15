//
//  main.m
//  Benchmarking
//
//  CocoaLumberjack Benchmarking
//

#import <Foundation/Foundation.h>

#import "PerformanceTesting.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [PerformanceTesting startPerformanceTests];
    }
    return 0;
}
