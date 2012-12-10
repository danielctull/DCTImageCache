//
//  DCTImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "DCTImageCache.h"
#import "_DCTImageCacheDiskCache.h"
#import "_DCTImageCacheMemoryCache.h"
#import "_DCTImageCacheFetcher.h"
#import "_DCTImageCacheProcessManager.h"
#import "_DCTImageCacheOperation.h"

@implementation DCTImageCache {
	_DCTImageCacheMemoryCache *_memoryCache;
	_DCTImageCacheDiskCache *_diskCache;
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
	_diskCache = [[_DCTImageCacheDiskCache alloc] initWithPath:path];
	_fetcher = [_DCTImageCacheFetcher new];
	_name = [name copy];
	_memoryCache = [_DCTImageCacheMemoryCache new];
	
	return self;
}

- (void)setImageFetcher:(DCTImageCacheFetcher)imageFetcher {
	_fetcher.imageFetcher = imageFetcher;
}

- (DCTImageCacheFetcher)imageFetcher {
	return _fetcher.imageFetcher;
}

- (void)removeAllImages {
	[_memoryCache removeAllImages];
	[_diskCache removeAllImages];
}

- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes {
	[_memoryCache removeImagesWithAttributes:attributes];
	[_diskCache removeImagesWithAttributes:attributes];
}

- (void)prefetchImageWithAttributes:(DCTImageCacheAttributes *)attributes {
	
	[_diskCache hasImageWithAttributes:attributes handler:^(BOOL hasImage, NSError *error) {

		if (hasImage) return;

		[_fetcher fetchImageWithAttributes:attributes handler:^(UIImage *image, NSError *error) {
			[_diskCache setImage:image forAttributes:attributes];
		}];
	}];
}

- (id<DCTImageCacheProcess>)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler {

	if (handler == NULL) {
		[self prefetchImageWithAttributes:attributes];
		return nil;
	}
	
	// If the image exists in the memory cache, use it!
	UIImage *image = [_memoryCache imageWithAttributes:attributes];
	if (image) {
		handler(image, nil);
		return nil;
	}

	// If the image is in the disk queue to be saved, pull it out and use it
	image = [_diskCache imageWithAttributes:attributes];
	if (image) {
		handler(image, nil);
		return nil;
	}

	_DCTImageCacheCancelProxy *cancelProxy = [_DCTImageCacheCancelProxy new];
	cancelProxy.imageHandler = handler;
	_DCTImageCacheProcessManager *processManager = [_DCTImageCacheProcessManager new];
	[processManager addCancelProxy:cancelProxy];
	
	processManager.process = [_diskCache fetchImageWithAttributes:attributes handler:^(UIImage *image, NSError *error) {

		if (image) {
			[_memoryCache setImage:image forAttributes:attributes];
			[processManager setImage:image];
			return;
		}

		processManager.process = [_fetcher fetchImageWithAttributes:attributes handler:^(UIImage *image, NSError *error) {
			[processManager setImage:image];
			[processManager setError:error];
			if (!image) return;
			[_memoryCache setImage:image forAttributes:attributes];
			[_diskCache setImage:image forAttributes:attributes];
		}];
	}];

	return cancelProxy;
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
