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
			[self downloadKey:key imageBlock:imageBlock];
		});
	};	
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)downloadKey:(NSString *)key imageBlock:(void(^)(UIImage *))imageBlock {
	NSURL *URL = [NSURL URLWithString:key];
	[_imageBlocks setObject:imageBlock forKey:URL];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
	[NSURLConnection connectionWithRequest:request delegate:self];
}

#pragma mark - NSURLConnectionDownloadDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSURL *URL = connection.originalRequest.URL;
	
	NSMutableData *imageData = [_datas objectForKey:URL];
	if (!imageData) {
		imageData = [NSMutableData new];
		[_datas setObject:imageData forKey:URL];
	}
	
	[imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSURL *URL = connection.originalRequest.URL;
	
	void(^imageBlock)(UIImage *) = [_imageBlocks objectForKey:URL];
	NSData *data = [_datas objectForKey:URL];
	UIImage *image = [UIImage imageWithData:data];
	imageBlock(image);
}

@end
