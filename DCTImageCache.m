//
//  DCTImageCache.m
//  Tweetville
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "DCTImageCache.h"
#import "UIImage+DCTCropping.h"


NSString *const DCTImageCacheOriginalImageName = @"OriginalImage";

@implementation DCTImageCache {
	__strong NSString *_path;
}

+ (void)load {
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		NSFileManager *fileManager = [NSFileManager new];
		NSString *cachePath = [[self class] defaultCachePath];
		NSArray *caches = [[fileManager contentsOfDirectoryAtPath:cachePath error:nil] copy];
		NSDate *now = [NSDate date];
		
		[caches enumerateObjectsUsingBlock:^(NSString *imageCacheName, NSUInteger i, BOOL *stop) {
			
			NSString *imageCachePath = [cachePath stringByAppendingPathComponent:imageCacheName];
			
			NSArray *imagePaths = [[fileManager contentsOfDirectoryAtPath:cachePath error:nil] copy];
			
			[imagePaths enumerateObjectsUsingBlock:^(NSString *key, NSUInteger i, BOOL *stop) {
				
				NSString *imagePath = [imageCachePath stringByAppendingPathComponent:key];
				NSString *originalImagePath = [imagePath stringByAppendingPathComponent:DCTImageCacheOriginalImageName];
				
				if (![fileManager fileExistsAtPath:originalImagePath]) {
					[fileManager removeItemAtPath:imagePath error:nil];
					return;
				}
				
				NSDictionary *attributes = [fileManager attributesOfItemAtPath:originalImagePath error:nil];
				NSDate *creationDate = [attributes objectForKey:NSFileCreationDate];
				
				NSTimeInterval timeInterval = [now timeIntervalSinceDate:creationDate];
				
				if (timeInterval > 604800) { // 7 days
					[fileManager removeItemAtPath:imagePath error:nil];
					return;
				}
			}];
		}];
	});
}

+ (DCTImageCache *)defaultImageCache {
	static DCTImageCache *sharedInstance = nil;
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString *defaultPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:NSStringFromClass(self)];
		defaultPath = [defaultPath stringByAppendingPathComponent:@"DefaultCache"];
		sharedInstance = [[self alloc] initWithPath:defaultPath];
	});
	return sharedInstance;
}

- (id)initWithName:(NSString *)name {
	if (!(self = [super init])) return nil;
	_name = [name copy];
	_path = [[[self class] defaultCachePath] stringByAppendingPathComponent:name];
	return self;
}

- (NSString *)directoryForKey:(NSString *)key {
	return [_path stringByAppendingPathComponent:key];
}

- (UIImage *)imageForKey:(NSString *)key {
	
	NSString *directoryPath = [self directoryForKey:key];
	NSString *imagePath = [directoryPath stringByAppendingPathComponent:DCTImageCacheOriginalImageName];
	
	NSData *data = [[NSFileManager defaultManager] contentsAtPath:imagePath];
	
	if (data) return [UIImage imageWithData:data];
	
	return nil;
}

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size {
	
	if (CGSizeEqualToSize(size, CGSizeZero)) return [self imageForKey:key];
	
	NSString *directoryPath = [self directoryForKey:key];
	NSString *imagePath = [directoryPath stringByAppendingPathComponent:NSStringFromCGSize(size)];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSData *data = [fileManager contentsAtPath:imagePath];
	
	if (data) return [UIImage imageWithData:data];
	
	UIImage *originalImage = [self imageForKey:key];
	
	if (!originalImage) return nil;
	
	UIImage *image = [originalImage dct_imageToFitSize:size];
	
	[self storeImage:image forKey:key size:size];
	
	return image;
}

- (void)fetchImageForKey:(NSString *)key imageBlock:(void (^)(UIImage *))block {
	[self fetchImageForKey:key size:CGSizeZero imageBlock:block];
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size imageBlock:(void (^)(UIImage *))block {
	
	UIImage *image = [self imageForKey:key size:size];
	
	if (image) {
		if (block != NULL) block(image);
		return;
	}
	
	if (self.imageDownloader == NULL) return;
	
	self.imageDownloader(key, ^(UIImage *image){
		[self storeImage:image forKey:key size:CGSizeZero];
		image = [self imageFromOriginalImage:image key:key size:size];
		if (block != NULL) block(image);
	});
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *directoryPath = [self directoryForKey:key];
	NSString *imagePath = [directoryPath stringByAppendingPathComponent:DCTImageCacheOriginalImageName];
	
	if (!CGSizeEqualToSize(size, CGSizeZero))
		imagePath = [directoryPath stringByAppendingPathComponent:NSStringFromCGSize(size)];
	
	if (![fileManager fileExistsAtPath:directoryPath])
		[fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
	
	[fileManager createFileAtPath:imagePath contents:UIImagePNGRepresentation(image) attributes:nil];
}

- (UIImage *)imageFromOriginalImage:(UIImage *)image key:(NSString *)key size:(CGSize)size {
	
	if (!image) return nil;
	
	if (!CGSizeEqualToSize(size, CGSizeZero)) {
		image = [image dct_imageToFitSize:size];
		[self storeImage:image forKey:key size:size];
	}
	
	return image;
	
}

+ (NSString *)defaultCachePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex:0] stringByAppendingPathComponent:NSStringFromClass(self)];
}

@end
