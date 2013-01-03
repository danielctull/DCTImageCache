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

NSString *const DCTImageCacheBundleName = @"DCTImageCache.bundle";
NSString *const DCTImageCacheDefaultCacheName = @"DCTDefaultImageCache";

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

+ (instancetype)defaultImageCache {
	return [self imageCacheWithName:DCTImageCacheDefaultCacheName];
}

+ (instancetype)imageCacheWithName:(NSString *)name {
	NSURL *URL = [[self _defaultDirectory] URLByAppendingPathComponent:name];
	return [self imageCacheWithURL:URL];
}

+ (instancetype)imageCacheWithURL:(NSURL *)storeURL {
	NSMutableDictionary *imageCaches = [self imageCaches];
	DCTImageCache *imageCache = [imageCaches objectForKey:storeURL];
	if (!imageCache) {
		imageCache = [[self alloc] _initWithStoreURL:storeURL];
		[imageCaches setObject:imageCache forKey:storeURL];
	}
	return imageCache;
}

- (id)_initWithStoreURL:(NSURL *)storeURL {
	self = [self init];
	if (!self) return nil;
	_diskCache = [[_DCTImageCacheDiskCache alloc] initWithStoreURL:storeURL];
	_fetcher = [_DCTImageCacheFetcher new];
	_name = [[storeURL lastPathComponent] copy];
	_memoryCache = [_DCTImageCacheMemoryCache new];
	return self;
}

- (NSURL *)storeURL {
	return _diskCache.storeURL;
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

- (id<DCTImageCacheProcess>)prefetchImageWithAttributes:(DCTImageCacheAttributes *)attributes
												handler:(DCTImageCacheHandler)handler {

	_DCTImageCacheCancelProxy *cancelProxy = [_DCTImageCacheCancelProxy new];
	cancelProxy.handler = handler;
	_DCTImageCacheProcessManager *processManager = [_DCTImageCacheProcessManager new];
	[processManager addCancelProxy:cancelProxy];

	processManager.process = [_diskCache hasImageWithAttributes:attributes handler:^(BOOL hasImage, NSError *diskError) {

		if (hasImage) {
			[processManager finishWithHasImage:hasImage error:diskError];
			return;
		}

		processManager.process = [_fetcher fetchImageWithAttributes:attributes handler:^(UIImage *image, NSError *fetchError) {
			[processManager finishWithImage:image error:fetchError];
			if (!image) return;
			[_diskCache setImage:image forAttributes:attributes];
		}];
	}];

	return cancelProxy;
}

- (id<DCTImageCacheProcess>)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes
											 handler:(DCTImageCacheImageHandler)handler {

	if (handler == NULL) return [self prefetchImageWithAttributes:attributes handler:NULL];
	
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
	
	processManager.process = [_diskCache fetchImageWithAttributes:attributes handler:^(UIImage *diskImage, NSError *diskError) {

		if (diskImage) {
			[_memoryCache setImage:diskImage forAttributes:attributes];
			[processManager finishWithImage:diskImage error:diskError];
			return;
		}

		processManager.process = [_fetcher fetchImageWithAttributes:attributes handler:^(UIImage *fetchImage, NSError *fetchError) {
			[processManager finishWithImage:fetchImage error:fetchError];
			if (!fetchImage) return;
			[_memoryCache setImage:fetchImage forAttributes:attributes];
			[_diskCache setImage:fetchImage forAttributes:attributes];
		}];
	}];

	return cancelProxy;
}

+ (NSURL *)cacheDirectoryURL {
	return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark Internal

+ (NSBundle *)_bundle {
	static NSBundle *bundle;
	static dispatch_once_t bundleToken;
	dispatch_once(&bundleToken, ^{
		NSDirectoryEnumerator *enumerator = [[NSFileManager new] enumeratorAtURL:[[NSBundle mainBundle] bundleURL]
													  includingPropertiesForKeys:nil
																		 options:NSDirectoryEnumerationSkipsHiddenFiles
																	errorHandler:NULL];

		for (NSURL *URL in enumerator)
			if ([[URL lastPathComponent] isEqualToString:DCTImageCacheBundleName])
				bundle = [NSBundle bundleWithURL:URL];
	});

	return bundle;
}

+ (NSURL *)_defaultDirectory {
	return [[self cacheDirectoryURL] URLByAppendingPathComponent:NSStringFromClass(self)];
}

@end
