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


// setDelegateQueue was broken on iOS 5...
BOOL CanSetDelegateQueue() {

	Class collectionViewClass = NSClassFromString(@"UICollectionView");
	Class tableViewClass = NSClassFromString(@"UITableView");

	if (tableViewClass && !collectionViewClass) return NO;

	return YES;
}

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
		NSURL *URL = [NSURL URLWithString:key];
		NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
		NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];

		if (CanSetDelegateQueue())
			[connection setDelegateQueue:[NSOperationQueue currentQueue]];

		[connection start];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

		if (!CanSetDelegateQueue())
			CFRunLoopRun();

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

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	if (!CanSetDelegateQueue())
		CFRunLoopStop(CFRunLoopGetCurrent());
}

- (UIImage *)imageFromImage:(UIImage *)image toFitSize:(CGSize)size {
	
	CGImageRef imageRef = image.CGImage;
	CGImageRetain(imageRef);
	CGFloat imageHeight = image.size.height;
	CGFloat imageWidth = image.size.width;
	CGFloat imageRatio = imageHeight/imageWidth;

	CGFloat height = size.height;
	CGFloat width = size.width;
	CGFloat ratio = height/width;

	CGRect imageRect = CGRectMake(0.0f, 0.0f, width, height);

	if (imageRatio < ratio) {
		NSInteger newImageWidth = imageWidth * height/imageHeight;
		NSInteger x = (NSInteger)(width-newImageWidth)/2.0f;
		imageRect = CGRectMake((CGFloat)x, 0.0f, (CGFloat)newImageWidth, height);
	} else if (imageRatio > ratio) {
		NSInteger newImageHeight = imageHeight * width/imageWidth;
		NSInteger y = (NSInteger)(height-newImageHeight)/2.0f;
		imageRect = CGRectMake(0.0f, y, width, newImageHeight);
	}
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, kCGImageAlphaNoneSkipLast);
	
	CGRect rect = CGRectMake(0.0f, 0.0f, width, height);
	CGContextSetFillColor(context, CGColorGetComponents([UIColor whiteColor].CGColor));
	CGContextFillRect(context, rect);
	
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
