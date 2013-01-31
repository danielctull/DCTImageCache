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

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	DCTImageCache *imageCache = [DCTImageCache defaultImageCache];
	imageCache.imageFetcher = ^(DCTImageCacheAttributes *attributes, id<DCTImageCacheCompletion> completion) {
		return [self fetchImageForAttributes:attributes completion:completion];
	};	
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (id<DCTImageCacheProcess>)fetchImageForAttributes:(DCTImageCacheAttributes *)attributes completion:(id<DCTImageCacheCompletion>)completion {

	NSString *URLString = [NSString stringWithFormat:@"http://lorempixel.com/%i/%i/city/%@", (NSInteger)attributes.size.width, (NSInteger)attributes.size.height, attributes.key];
	NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), URLString);
	NSURL *URL = [NSURL URLWithString:URLString];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		UIImage *image = [UIImage imageWithData:data];
		[completion finishWithImage:image error:error];
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}];
	return nil;
}



@end
