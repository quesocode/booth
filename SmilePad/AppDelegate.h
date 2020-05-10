//
//  AppDelegate.h
//  Airplanes and Blazers
//
//  Created by Travis Weerts on 6/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tiny.h"



@interface AppDelegate : UIResponder <UIApplicationDelegate, TinyDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (BOOL) isIpad;
- (BOOL) routeURL:(NSURL *)url;
@end
