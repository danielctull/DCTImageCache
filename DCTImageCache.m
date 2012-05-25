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
		
		NSDate *now = [NSDate date];
		
		[self enumerateImageCachesUsingBlock:^(DCTImageCache *imageCache, BOOL *stop) {
			
			
			[imageCache enumerateKeysUsingBlock:^(NSString *key, BOOL *stop) {
				
				NSDictionary *attributes = [imageCache attributesForImageWithKey:key];
				
				if (!attributes) {
					[imageCache deleteImagesForKey:key];
					return;
				}
				
				NSDate *creationDate = [attributes objectForKey:NSFileCreationDate];
				NSTimeInterval timeInterval = [now timeIntervalSinceDate:creationDate];
				
				if (timeInterval > 604800) // 7 days
					[imageCache deleteImagesForKey:key];
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

- (UIImage *)imageForKey:(NSString *)key {
	return [self imageForKey:key size:CGSizeZero];
}

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size {
	
	NSString *imagePath = [self imagePathForKey:key size:size];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSData *data = [fileManager contentsAtPath:imagePath];
	UIImage *image = [UIImage imageWithData:data];
	
	if (!image && !CGSizeEqualToSize(size, CGSizeZero)) {
		UIImage *originalImage = [self imageForKey:key];
		image = [self imageFromOriginalImage:originalImage key:key size:size];
	}
	
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

#pragma mark - Internal

- (void)storeKey:(NSString *)key forHash:(NSString *)hash {
	NSString *hashKeyPath = [_path stringByAppendingPathComponent:@".hashes"];
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:hashKeyPath];
	if (!dictionary) dictionary = [NSMutableDictionary new];
	
	if (key) [dictionary setObject:key forKey:hash];
	else [dictionary removeObjectForKey:hash];
	
	[dictionary writeToFile:hashKeyPath atomically:YES];
}

- (NSString *)keyForHash:(NSString *)hash {
	NSString *hashKeyPath = [_path stringByAppendingPathComponent:@".hashes"];
	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:hashKeyPath];
	return [dictionary objectForKey:hash];
}

- (NSString *)hashForKey:(NSString *)key {
	return [NSString stringWithFormat:@"%u", [key hash]];
}

- (NSString *)directoryForKey:(NSString *)key {
	return [_path stringByAppendingPathComponent:[self hashForKey:key]];
}

- (NSString *)imagePathForKey:(NSString *)key size:(CGSize)size {
	
	NSString *sizeString = DCTImageCacheOriginalImageName;
	if (!CGSizeEqualToSize(size, CGSizeZero)) sizeString = NSStringFromCGSize(size);
	
	NSString *path = [self directoryForKey:key];
	path = [path stringByAppendingPathComponent:sizeString];
	return path;
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *directoryPath = [self directoryForKey:key];
	NSString *imagePath = [directoryPath stringByAppendingPathComponent:DCTImageCacheOriginalImageName];
	
	if (!CGSizeEqualToSize(size, CGSizeZero))
		imagePath = [directoryPath stringByAppendingPathComponent:NSStringFromCGSize(size)];
	else
		[self storeKey:key forHash:[self hashForKey:key]];
	
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

+ (void)enumerateImageCachesUsingBlock:(void (^)(DCTImageCache *imageCache, BOOL *stop))block {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *cachePath = [[self class] defaultCachePath];
	NSArray *caches = [[fileManager contentsOfDirectoryAtPath:cachePath error:nil] copy];
	
	[caches enumerateObjectsUsingBlock:^(NSString *name, NSUInteger i, BOOL *stop) {
		DCTImageCache *imageCache = [[DCTImageCache alloc] initWithName:name];
		block(imageCache, stop);
	}];
}

- (void)enumerateKeysUsingBlock:(void (^)(NSString *key, BOOL *stop))block {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *filenames = [[fileManager contentsOfDirectoryAtPath:_path error:nil] copy];
	
	[filenames enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger i, BOOL *stop) {
		NSString *key = [self keyForHash:filename];
		block(key, stop);
	}];
}

- (NSDictionary *)attributesForImageWithKey:(NSString *)key {
	NSString *path = [self imagePathForKey:key size:CGSizeZero];
	return [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
}
- (void)deleteImagesForKey:(NSString *)key {
	[self storeKey:nil forHash:[self hashForKey:key]];
	NSString *directoryPath = [self directoryForKey:key];
	[[NSFileManager defaultManager] removeItemAtPath:directoryPath error:nil];
}

@end
