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

@implementation DCTImageCache {
	__strong _DCTDiskImageCache *_diskCache;
	__strong _DCTMemoryImageCache *_memoryCache;
	__strong NSMutableDictionary *_imageHandlers;
	__strong NSOperationQueue *_queue;
	__strong NSMutableSet *_fetchingKeySizes;
}

#pragma mark NSObject

+ (void)initialize {
	@autoreleasepool {
		NSDate *now = [NSDate date];
		
		[self _enumerateImageCachesUsingBlock:^(DCTImageCache *imageCache, BOOL *stop) {
			
			_DCTDiskImageCache *diskCache = imageCache.diskCache;
			[diskCache enumerateKeysUsingBlock:^(NSString *key, BOOL *stop) {
			
				[diskCache fetchAttributesForImageWithKey:key size:CGSizeZero handler:^(NSDictionary *attributes) {
				
					if (!attributes) {
						[diskCache removeAllImagesForKey:key];
						return;
					}
						
					NSDate *creationDate = [attributes objectForKey:NSFileCreationDate];
					NSTimeInterval timeInterval = [now timeIntervalSinceDate:creationDate];
					
					if (timeInterval > 604800) // 7 days
						[diskCache removeAllImagesForKey:key];
				}];
			}];
		}];
	}
}

#pragma mark DCTImageCache

- (id<DCTImageCache>)diskCache {
	return _diskCache;
}

- (id<DCTImageCache>)memoryCache {
	return _memoryCache;
}

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
	
	NSString *queueName = [NSString stringWithFormat:@"uk.co.danieltull.DCTImageCache.%@", name];
	_queue = [NSOperationQueue new];
	[_queue setMaxConcurrentOperationCount:1];
	[_queue setName:queueName];
	
	[self _performWithPriority:NSOperationQueuePriorityNormal block:^{
		_name = [name copy];
		_memoryCache = [_DCTMemoryImageCache new];
		_imageHandlers = [NSMutableDictionary new];
		NSString *path = [[[self class] _defaultCachePath] stringByAppendingPathComponent:name];
		_diskCache = [[_DCTDiskImageCache alloc] initWithPath:path];
		_fetchingKeySizes = [NSMutableSet new];
	}];
	
	return self;
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

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size; {
	UIImage *image = [_memoryCache imageForKey:key size:size];
	if (image) return image;
	
	image = [_diskCache imageForKey:key size:size];
	if (image) [_memoryCache setImage:image forKey:key size:size];
	return image;
}

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size {
	
	if ([_memoryCache hasImageForKey:key size:size])
		return YES;
	
	return [_diskCache hasImageForKey:key size:size];
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void (^)(UIImage *))handler {
	
	UIImage *image = [_memoryCache imageForKey:key size:size];
	if (image) {
		if (handler != NULL) handler(image);
		return;
	}
	
	NSOperationQueuePriority priority = NSOperationQueuePriorityVeryLow;
	if (handler != NULL) priority = NSOperationQueuePriorityVeryHigh;

	[self _performWithPriority:priority block:^{

		NSString *accessKey = [self _accessKeyForKey:key size:size];
		[self _addHandler:handler forAccessKey:accessKey];

		if ([self _isRetrievingImageForAccessKey:accessKey]) return;
		[self _setRetrieving:YES forImageForAccessKey:accessKey];
		
		[_diskCache fetchImageForKey:key size:size handler:^(UIImage *image) {
			
			if (image) {
				[self _sendImage:image toHandlersForKey:key size:size];
				return;
			}
			
			if (self.imageFetcher != NULL)
				self.imageFetcher(key, size);
		}];
	}];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	[_diskCache setImage:image forKey:key size:size];
	[self _sendImage:image toHandlersForKey:key size:size];
}

#pragma mark Internal

- (NSString *)_accessKeyForKey:(NSString *)key size:(CGSize)size {
	return [NSString stringWithFormat:@"%@+%@", key, NSStringFromCGSize(size)];
}

- (void)_setRetrieving:(BOOL)retrieving forImageForAccessKey:(NSString *)accessKey {
	if (retrieving) [_fetchingKeySizes addObject:accessKey];
	else [_fetchingKeySizes removeObject:accessKey];
}

- (BOOL)_isRetrievingImageForAccessKey:(NSString *)accessKey {
	return [_fetchingKeySizes containsObject:accessKey];
}

- (void)_performWithPriority:(NSOperationQueuePriority)priority block:(void(^)())block {
	NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:block];
	[blockOperation setQueuePriority:priority];
	[_queue addOperation:blockOperation];
}

- (void)_removeHandlerForAccessKey:(NSString *)accessKey {
	[_imageHandlers removeObjectForKey:accessKey];
}

- (void)_addHandler:(void(^)(UIImage *))handler forAccessKey:(NSString *)accessKey {
	if (handler == NULL) return;

	NSMutableArray *handlers = [_imageHandlers objectForKey:accessKey];
	if (!handlers) {
		handlers = [NSMutableArray new];
		[_imageHandlers setObject:handlers forKey:accessKey];
	}
	[handlers addObject:handler];
}

- (NSArray *)_imageHandlersForAccessKey:(NSString *)accessKey {
	return [_imageHandlers objectForKey:accessKey];
}

- (void)_sendImage:(UIImage *)image toHandlersForKey:(NSString *)key size:(CGSize)size {
	[self _performWithPriority:NSOperationQueuePriorityVeryHigh block:^{
		NSString *accessKey = [self _accessKeyForKey:key size:size];
		[self _setRetrieving:NO forImageForAccessKey:accessKey];
		NSArray *handlers = [self _imageHandlersForAccessKey:accessKey];
		if (!handlers) return;
		[_memoryCache setImage:image forKey:key size:size];
		[handlers enumerateObjectsUsingBlock:^(void(^handler)(UIImage *), NSUInteger idx, BOOL *stop) {
			handler(image);
		}];
		[self _removeHandlerForAccessKey:accessKey];
	}];
}

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
