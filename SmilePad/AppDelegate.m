//
//  AppDelegate.m
//  Airplanes and Blazers
//
//  Created by Travis Weerts on 6/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "TinyConstants.h"
#import "TinyAPI.h"
#import "TinyEvent.h"
#import "TinyStyles.h"
#import "Tiny.h"
#import "TinyUI.h"
#import "NSDictionary_JSONExtensions.h"
#import "TinyViewBuilder.h"
#import "SDURLCache.h"
#import "TinyFileManager.h"

@implementation AppDelegate

@synthesize window = _window;


#pragma mark -
#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    SDURLCache *urlCache = [[SDURLCache alloc] initWithMemoryCapacity:1024*1024   // 1MB mem cache
                                                         diskCapacity:1024*1024*5 // 5MB disk cache
                                                             diskPath:[TinyFileManager downloadsCachePath]];
    [urlCache setIgnoreMemoryOnlyStoragePolicy:YES];
    [urlCache setMinCacheInterval:1];
    [NSURLCache setSharedURLCache:urlCache];
    
    [urlCache release];
    
    
    // Let the device know we want to receive push notifications
    //    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
    //     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    
    
    
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    NSString *settingsFile = [[NSString alloc] initWithString:[[NSBundle mainBundle] pathForResource:@"Tiny-Settings" ofType:@"plist"]];
	NSDictionary *settingsDict = [[NSDictionary alloc] initWithContentsOfFile:settingsFile];
    if(settingsDict)
    {
        UIViewController *viewController = [[UIViewController alloc] init];
        if([[settingsDict objectForKey:@"screen"] objectForKey:@"style"])
        {
            TinyStyles *styles = [[TinyStyles alloc] initWithProperties:[[settingsDict objectForKey:@"screen"] objectForKey:@"style"] withOwner:viewController.view];
            [styles applyToView:viewController.view];
            [styles release];
        }
        else {
            // need to replace this with the latest screenshot of the home screen
            viewController.view.backgroundColor = [UIColor blackColor];
        }
        self.window.rootViewController= viewController;
        [viewController release];
        //[TinyFileManager removeCache];
        Tiny * MYTINY = [[Tiny engineWithOptions:settingsDict] retain];
        [TinyAPI initWithProps:[settingsDict objectForKey:@"api"]];
        [TinyAPI addParams:[settingsDict objectForKey:@"app"]];
        MYTINY.configURLString = [TinyAPI gatewayURLString];
        MYTINY.appID = [settingsDict valueForKeyPath:@"api.appId"];
        MYTINY.delegate = self;
        MYTINY.saveConfig = [settingsDict valueForKeyPath:@"api.cache"] ? [[settingsDict valueForKeyPath:@"api.cache"] boolValue] : YES;
        MYTINY.autoupdate = [[settingsDict valueForKeyPath:@"app.autoupdate"] boolValue];
        MYTINY.liveupdate = [[settingsDict valueForKeyPath:@"app.liveupdate"] boolValue];
        if([settingsDict valueForKeyPath:@"app.liveupdateInterval"]) MYTINY.liveupdateInterval = [[settingsDict valueForKeyPath:@"app.liveupdateInterval"] floatValue];
        [MYTINY load:settingsDict];
        
    }
    [settingsFile release], settingsFile=nil;
    [settingsDict release], settingsDict=nil;
    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark -
#pragma mark TinyDelegate

- (void) tinyDidLoad:(id)sender
{
    self.window.rootViewController = [TinyUI rootViewController];
    //    @try {
    //        self.window.rootViewController = [TinyUI rootViewController];
    //    }
    //    @catch (NSException *exception) {
    //        DLog(@"TinyDidLoad ERROR: %@", exception);
    //        DLog(@"callStack: %@", exception.callStackSymbols);
    //    }
    
    
}

- (void)tiny:(id)sender didNotLoadWithError:(NSError *)error
{
    DLog(@"Tiny did not load: %@", error.localizedDescription);
}

- (void) tinyDidReload:(id)sender
{
    DLog(@"tiny did reload:");
    UIViewController *newcontroller = [TinyUI rootViewController];
    self.window.rootViewController = newcontroller;
}

- (void) tinyWillReload:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tiny-reload" object:self];
    [TinyUI reload];
    
}

- (void) tiny:(id)sender didFinishDownloading:(NSURLConnection *)connection
{
    
}

- (void) tiny:(id)sender didFailWithError:(NSError *)error connection:(NSURLConnection *)connection
{
    DLog(@"Tiny failed to launch: %@", error.localizedDescription);
    [Tiny alertWithError:error title:@"Unable to launch" message:@"Please check your internet connection, and try restarting this app. If this continues, contact the owner of this app for support."];
}

#pragma mark -
#pragma mark TinyDelegate - Updated config

- (void) tinyStartedLiveUpdates:(id)sender
{
    //DLog(@"starting live updates");
}

- (void) tinyStoppedLiveUpdates:(id)sender
{
    //DLog(@"stopping live updates");
}

- (void) tinyNewerVersionIsAvailable:(id)sender
{
    //DLog(@"Tiny Newer version saved to file");
    [[Tiny instance] reload];
}

- (void) tinyWillCheckForUpdate:(id)sender
{
    //DLog(@"Tiny will check for update");
}

- (void) tinyDidFinishCheckingForUpdate:(id)sender
{
    
}

- (void) tinyVersionIsCurrent:(id)sender
{
    //DLog(@"Tiny version is current");
}

+ (BOOL) isIpad
{
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    
    if(screenRect.size.width <= 480 || screenRect.size.height <= 480)
    {
        return NO;
    }
    return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    if([Tiny hasLiveUpdateStarted])
    {
        [Tiny stopLiveUpdate];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if([Tiny hasLiveUpdateStarted])
    {
        [Tiny startLiveUpdate];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -
#pragma mark URL routing

- (BOOL) routeURL:(NSURL *)url
{
    NSString *queryStr = [[[url absoluteString] componentsSeparatedByString:@"?"] lastObject];
    
    NSString* escapedQuery = [queryStr stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    
    NSDictionary *params = [TinyAPI parseQueryString:escapedQuery];
    if([params objectForKey:@"action"])
    {
        NSError *theError = NULL;
        NSDictionary *eventEvents = nil;
        if([[params objectForKey:@"action"] hasPrefix:@"{"])
        {
            eventEvents = [NSDictionary dictionaryWithJSONString:[params objectForKey:@"action"] error:&theError];
        }
        else
        {
            eventEvents = [NSDictionary dictionaryWithObject:params forKey:[params objectForKey:@"action"]];
        }
        if(eventEvents)
        {
            [TinyEvent performEvents:eventEvents withObject:[Tiny instance]];
            return NO;
        }
        
    }
    return YES;
}



- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self routeURL:url];
}


#pragma mark -
#pragma mark Push Notification Callbacks

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	DLog(@"My token is: %@", deviceToken);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    if(error.code != 3010)
    {
        NSLog(@"Failed to get token, error: %@", error);
    }
}



@end
