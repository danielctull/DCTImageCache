//
//  AppDelegate.m
//  DCTImageCaccheDemo
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <DCTImageCache/DCTImageCache.h>

@interface AppDelegate () <DCTImageCacheDelegate>
@property (nonatomic) DCTImageCache *imageCache;
@property (nonatomic) NSInteger networkActivity;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	NSURL *cacheDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
	NSURL *URL = [cacheDirectory URLByAppendingPathComponent:@"Image Cache Test"];
	self.imageCache = [DCTImageCache imageCacheWithURL:URL];
	self.imageCache.delegate = self;

	id rootViewController = self.window.rootViewController;
	NSAssert([rootViewController isKindOfClass:[UINavigationController class]], @"Root view controller should be a UINavigationController, %@", rootViewController);
	UINavigationController *navigationController = rootViewController;

	id topViewController = navigationController.topViewController;
	NSAssert([topViewController isKindOfClass:[ViewController class]], @"Top view controller should be a ViewController, %@", topViewController);
	ViewController *viewController = topViewController;

	viewController.imageCache = self.imageCache;

    return YES;
}

- (void)setNetworkActivity:(NSInteger)networkActivity {
	_networkActivity = networkActivity;

	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:networkActivity > 0];
}

#pragma mark - DCTImageCacheDelegate

- (void)imageCache:(DCTImageCache *)imageCache fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler {

	NSInteger width = (NSInteger)(attributes.size.width * attributes.scale);
	NSInteger height = (NSInteger)(attributes.size.height * attributes.scale);
	NSString *URLString = [NSString stringWithFormat:@"http://lorempixel.com/%@/%@/city/%@", @(width), @(height), attributes.key];
	NSLog(@"FETCHING: %@", attributes.key);
	NSURL *URL = [NSURL URLWithString:URLString];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
	self.networkActivity++;
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		self.networkActivity--;
		UIImage *image = [UIImage imageWithData:data];
		handler(image, error);
	}];
}

@end
