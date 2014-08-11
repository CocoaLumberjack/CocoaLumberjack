//
//  UniversalAppAppDelegate.h
//  UniversalApp
//
//  Created by Robbie Hanson on 7/1/10.
//

#import <UIKit/UIKit.h>

@class UniversalAppViewController;

@interface UniversalAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UniversalAppViewController *viewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UniversalAppViewController *viewController;

@end

