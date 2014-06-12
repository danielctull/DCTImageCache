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

static NSString *const DCTImageCacheBundleName = @"DCTImageCache.bundle";
static NSString *const DCTImageCacheDefaultCacheName = @"DCTDefaultImageCache";

@interface DCTImageCache ()
@property (nonatomic) _DCTImageCacheMemoryCache *memoryCache;
@property (nonatomic) _DCTImageCacheDiskCache *diskCache;
@end

@implementation DCTImageCache

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
	_name = [[storeURL lastPathComponent] copy];
	_memoryCache = [_DCTImageCacheMemoryCache new];
	return self;
}

- (NSURL *)storeURL {
	return self.diskCache.URL;
}

- (void)removeAllImages {
	
	NSProgress *progress = [NSProgress progressWithTotalUnitCount:2];

	[progress becomeCurrentWithPendingUnitCount:1];
	[self.memoryCache removeAllImages];
	[progress resignCurrent];

	[progress becomeCurrentWithPendingUnitCount:1];
	[self.diskCache removeAllImages];
	[progress resignCurrent];
}

- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes {

	NSProgress *progress = [NSProgress progressWithTotalUnitCount:2];

	[progress becomeCurrentWithPendingUnitCount:1];
	[self.memoryCache removeImagesWithAttributes:attributes];
	[progress resignCurrent];

	[progress becomeCurrentWithPendingUnitCount:1];
	[self.diskCache removeImagesWithAttributes:attributes];
	[progress resignCurrent];
}

- (void)prefetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(void(^)(NSError *error))handler {

	NSProgress *progress = [NSProgress progressWithTotalUnitCount:2];

	handler = ^(NSError *error){

		if (handler && !progress.cancelled) {
			handler(error);
		}

		if (progress.completedUnitCount != progress.totalUnitCount) {
			progress.completedUnitCount = progress.totalUnitCount;
		}
	};

	[progress becomeCurrentWithPendingUnitCount:1];
	[self.diskCache hasImageWithAttributes:attributes handler:^(BOOL hasImage, NSError *error) {

		if (hasImage) {
			handler(nil);
			return;
		}

		[progress becomeCurrentWithPendingUnitCount:1];
		[self.delegate imageCache:self fetchImageWithAttributes:attributes handler:^(UIImage *image, NSError *error) {
			handler(error);
			if (!image) return;

			[self.diskCache setImage:image forAttributes:attributes];
		}];
		[progress resignCurrent];
	}];
	[progress resignCurrent];
}

- (void)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler {

	if (!handler) {
		[self prefetchImageWithAttributes:attributes handler:nil];
		return;
	}
	
	// If the image exists in the memory cache, use it!
	DCTImageCacheImage *image = [self.memoryCache imageWithAttributes:attributes];
	if (image) {
		handler(image, nil);
		return;
	}

	NSProgress *progress = [NSProgress progressWithTotalUnitCount:2];

	// Make sure we don't call the handler if the process is cancelled
	handler = ^(DCTImageCacheImage *image, NSError *error){

		if (!progress.cancelled) {

			if (progress.completedUnitCount != progress.totalUnitCount) {
				progress.completedUnitCount = progress.totalUnitCount;
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				if (!progress.cancelled) {
					handler(image, error);
				}
			});
		}
	};

	[progress becomeCurrentWithPendingUnitCount:1];
	[self.diskCache fetchImageWithAttributes:attributes handler:^(DCTImageCacheImage *image, NSError *error) {

		if (image) {
			[self.memoryCache setImage:image forAttributes:attributes];
			handler(image, error);
			return;
		}

		[progress becomeCurrentWithPendingUnitCount:1];
		[self.delegate imageCache:self fetchImageWithAttributes:attributes handler:^(UIImage *image, NSError *error) {

			handler(image, error);

			if (image) {
				[self.memoryCache setImage:image forAttributes:attributes];
				[self.diskCache setImage:image forAttributes:attributes];
			}
		}];
		[progress resignCurrent];
	}];
	[progress resignCurrent];
}

+ (NSURL *)cacheDirectoryURL {
	return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark Internal

+ (NSBundle *)bundle {
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
