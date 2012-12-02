//
//  DCTImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "DCTImageCache.h"
#import "_DCTDiskImageCache.h"
#import "_DCTMemoryImageCache.h"
#import "_DCTImageCacheFetcher.h"
#import "_DCTImageCacheHandler.h"

#import "_DCTImageCacheOperation.h"
#import "NSOperationQueue+_DCTImageCache.h"

@implementation DCTImageCache {
	_DCTMemoryImageCache *_memoryCache;
	_DCTDiskImageCache *_diskCache;
	_DCTImageCacheFetcher *_fetcher;
}

#pragma mark DCTImageCache

+ (NSMutableDictionary *)imageCaches {
	static NSMutableDictionary *sharedInstance = nil;
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		sharedInstance = [NSMutableDictionary new];
	});
	return sharedInstance;
}

+ (DCTImageCache *)defaultImageCache {
	return [self imageCacheWithName:@"DCTDefaultImageCache"];
}

+ (DCTImageCache *)imageCacheWithName:(NSString *)name {
	
	NSMutableDictionary *imageCaches = [self imageCaches];
	DCTImageCache *imageCache = [imageCaches objectForKey:name];
	if (!imageCache) {
		imageCache = [[self alloc] _initWithName:name];
		[imageCaches setObject:imageCache forKey:name];
	}
	return imageCache;
}

- (id)_initWithName:(NSString *)name {
	
	self = [self init];
	if (!self) return nil;

	NSString *path = [[[self class] _defaultCachePath] stringByAppendingPathComponent:name];
	_diskCache = [[_DCTDiskImageCache alloc] initWithPath:path];
	_fetcher = [_DCTImageCacheFetcher new];
	_name = [name copy];
	_memoryCache = [_DCTMemoryImageCache new];
	
	return self;
}

- (void)setImageFetcher:(id<DCTImageCacheCanceller> (^)(NSString *, CGSize, id<DCTImageCacheSetter>))imageFetcher {
	[_fetcher setImageFetcher:imageFetcher];
}

- (id<DCTImageCacheCanceller> (^)(NSString *, CGSize, id<DCTImageCacheSetter>))imageFetcher {
	return [_fetcher imageFetcher];
}

- (void)removeAllImages {
	[_memoryCache removeAllImages];
	[_diskCache removeAllImages];
}

- (void)removeAllImagesForKey:(NSString *)key {
	[_memoryCache removeAllImagesForKey:key];
	[_diskCache removeAllImagesForKey:key];
}

- (void)removeImageForKey:(NSString *)key size:(CGSize)size {
	[_memoryCache removeImageForKey:key size:size];
	[_diskCache removeImageForKey:key size:size];
}

- (void)prefetchImageForKey:(NSString *)key size:(CGSize)size {
	
	[_diskCache hasImageForKey:key size:size handler:^(BOOL hasImage) {

		if (hasImage) return;

		[_fetcher fetchImageForKey:key size:size handler:^(UIImage *image) {
			[_diskCache setImage:image forKey:key size:size];
		}];
	}];
}

- (id<DCTImageCacheCanceller>)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void (^)(UIImage *))handler {

	if (handler == NULL) {
		[self prefetchImageForKey:key size:size];
		return nil;
	}
	
	// If the image exists in the memory cache, use it!
	UIImage *image = [_memoryCache imageForKey:key size:size];
	if (image) {
		handler(image);
		return nil;
	}

	// If the image is in the disk queue to be saved, pull it out and use it
	image = [_diskCache imageForKey:key size:size];
	if (image) {
		handler(image);
		return nil;
	}

	_DCTImageCacheHandler *cacheHandler = [_DCTImageCacheHandler new];
	cacheHandler.handler = [_diskCache fetchImageForKey:key size:size handler:^(UIImage *image) {

		if (image) {
			[_memoryCache setImage:image forKey:key size:size];
			handler(image);
			return;
		}

		cacheHandler.handler = [_fetcher fetchImageForKey:key size:size handler:^(UIImage *image) {
			handler(image);
			[_memoryCache setImage:image forKey:key size:size];
			[_diskCache setImage:image forKey:key size:size];
		}];
	}];
	return cacheHandler;
}

#pragma mark Internal

+ (NSString *)_defaultCachePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex:0] stringByAppendingPathComponent:NSStringFromClass(self)];
}

+ (void)_enumerateImageCachesUsingBlock:(void (^)(DCTImageCache *imageCache, BOOL *stop))block {
	NSFileManager *fileManager = [NSFileManager new];
	NSString *cachePath = [[self class] _defaultCachePath];
	NSArray *caches = [[fileManager contentsOfDirectoryAtPath:cachePath error:nil] copy];
	
	[caches enumerateObjectsUsingBlock:^(NSString *name, NSUInteger i, BOOL *stop) {
		DCTImageCache *imageCache = [DCTImageCache imageCacheWithName:name];
		block(imageCache, stop);
	}];
}

@end
