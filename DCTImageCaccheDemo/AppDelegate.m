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
	__strong NSMutableDictionary *_datas;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	_datas = [NSMutableDictionary new];
	
	DCTImageCache *imageCache = [DCTImageCache defaultImageCache];
	imageCache.imageFetcher = ^(NSString *key, CGSize size) {
		[self fetchImageForKey:key size:size];
	};	
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size {
	
	if (CGSizeEqualToSize(size, CGSizeZero)) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSURL *URL = [NSURL URLWithString:key];
			NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
			[NSURLConnection connectionWithRequest:request delegate:self];
		});
		return;
	}
	
	[[DCTImageCache defaultImageCache] fetchImageForKey:key size:CGSizeZero handler:^(UIImage *image) {
		UIImage *scaledImage = [self imageFromImage:image toFitSize:size];
		[[DCTImageCache defaultImageCache] setImage:scaledImage forKey:key size:size];
	}];
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
	NSData *data = [_datas objectForKey:URL];
	UIImage *image = [UIImage imageWithData:data];
	DCTImageCache *imageCache = [DCTImageCache defaultImageCache];
	[imageCache setImage:image forKey:[URL absoluteString] size:CGSizeZero];
}

- (UIImage *)imageFromImage:(UIImage *)image toFitSize:(CGSize)size {
	
	CGImageRef imageRef = image.CGImage;
	CGFloat height = image.size.height;
	CGFloat width = image.size.width;
	
	if (height < width) {
		NSInteger x = (NSInteger)(width-height)/2.0f;
		imageRef = CGImageCreateWithImageInRect(imageRef, CGRectMake((CGFloat)x, 0.0f, height, height));
		
	} else if (height > width) {
		NSInteger y = (NSInteger)(height-width)/2.0f;
		imageRef = CGImageCreateWithImageInRect(imageRef, CGRectMake(0.0f, y, width, width));
		
	} else {
		CGImageRetain(imageRef);
	}
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaNoneSkipLast);
	
	CGRect imageRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
	
	CGContextSetFillColor(context, CGColorGetComponents([UIColor whiteColor].CGColor));
	CGContextFillRect(context, imageRect);
	
	CGContextDrawImage(context, imageRect, imageRef);
	
	CGImageRef scaledImageRef = CGBitmapContextCreateImage(context);
	UIImage *scaledImage = [UIImage imageWithCGImage:scaledImageRef];
	
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);
	CGImageRelease(imageRef);
	CGImageRelease(scaledImageRef);
	
	return scaledImage;
}

@end
