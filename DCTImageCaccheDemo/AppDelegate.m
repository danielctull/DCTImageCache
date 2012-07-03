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

@implementation AppDelegate {
	__strong NSMutableDictionary *_imageBlocks;
	__strong NSMutableDictionary *_datas;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	_imageBlocks = [NSMutableDictionary new];
	_datas = [NSMutableDictionary new];
	
	DCTImageCache *imageCache = [DCTImageCache defaultImageCache];
	imageCache.imageFetcher = ^(NSString *key, CGSize size, void(^imageBlock)(UIImage *)) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self downloadURL:[NSURL URLWithString:key] imageBlock:imageBlock];
		});
	};	
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)downloadURL:(NSURL *)URL imageBlock:(void(^)(UIImage *))imageBlock {
	[_imageBlocks setObject:imageBlock forKey:URL];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
	[NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark - NSURLConnectionDownloadDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	
	NSMutableData *imageData = [_datas objectForKey:connection.originalRequest.URL];
	if (!imageData) {
		imageData = [NSMutableData new];
		[_datas setObject:imageData forKey:connection.originalRequest.URL];
	}
	
	[imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	void(^imageBlock)(UIImage *) = [_imageBlocks objectForKey:connection.originalRequest.URL];
	NSData *data = [_datas objectForKey:connection.originalRequest.URL];
	UIImage *image = [UIImage imageWithData:data];
	imageBlock(image);
}

@end
