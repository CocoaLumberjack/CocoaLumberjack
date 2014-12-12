
#import <Foundation/Foundation.h>

@class LeNetworkStatus;

@protocol LeNetworkStatusDelegete <NSObject>

- (void)networkStatusDidChange:(LeNetworkStatus*)networkStatus;

@end

@interface LeNetworkStatus: NSObject

@property (nonatomic, weak) id<LeNetworkStatusDelegete> delegate;
- (BOOL)connected;

@end


