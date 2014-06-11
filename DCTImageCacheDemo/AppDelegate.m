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
@property (nonatomic) ViewController *viewController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	DCTImageCache *imageCache = [DCTImageCache defaultImageCache];
	imageCache.delegate = self;
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark - DCTImageCacheDelegate

- (void)imageCache:(DCTImageCache *)imageCache fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler {

	NSInteger width = (NSInteger)(attributes.size.width * attributes.scale);
	NSInteger height = (NSInteger)(attributes.size.height * attributes.scale);
	NSString *URLString = [NSString stringWithFormat:@"http://lorempixel.com/%@/%@/city/%@", @(width), @(height), attributes.key];
	NSLog(@"FETCHING\n%@\n%@\n\n", attributes, URLString);
	NSURL *URL = [NSURL URLWithString:URLString];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		UIImage *image = [UIImage imageWithData:data];
		handler(image, error);
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}];
}

@end
