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

#import "_DCTImageCacheFetchOperation.h"
#import "_DCTImageCacheSaveOperation.h"
#import "_DCTImageCacheImageOperation.h"

@implementation DCTImageCache {
	_DCTMemoryImageCache *_memoryCache;

	NSOperationQueue *_diskQueue;
	_DCTDiskImageCache *_diskCache;

	NSOperationQueue *_queue;
}

#pragma mark NSObject
/*
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
*/
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

	_diskQueue = [NSOperationQueue new];
	_diskQueue.maxConcurrentOperationCount = 1;
	_diskQueue.name = [NSString stringWithFormat:@"uk.co.danieltull.DCTImageCacheDiskQueue.%@", name];
	[_diskQueue addOperationWithBlock:^{
		NSString *path = [[[self class] _defaultCachePath] stringByAppendingPathComponent:name];
		_diskCache = [[_DCTDiskImageCache alloc] initWithPath:path];
	}];

	_queue = [NSOperationQueue new];
	_queue.maxConcurrentOperationCount = 10;
	_queue.name = [NSString stringWithFormat:@"uk.co.danieltull.DCTImageCacheQueue.%@", name];

	_name = [name copy];
	_memoryCache = [_DCTMemoryImageCache new];
	
	return self;
}

- (void)removeAllImages {
	[_memoryCache removeAllImages];
	[self _performVeryLowPriorityBlockOnDiskQueue:^{
		[_diskCache removeAllImages];
	}];
}

- (void)removeAllImagesForKey:(NSString *)key {
	[_memoryCache removeAllImagesForKey:key];
	[self _performVeryLowPriorityBlockOnDiskQueue:^{
		[_diskCache removeAllImagesForKey:key];
	}];
}

- (void)removeImageForKey:(NSString *)key size:(CGSize)size {
	[_memoryCache removeImageForKey:key size:size];
	[self _performVeryLowPriorityBlockOnDiskQueue:^{
		[_diskCache removeImageForKey:key size:size];
	}];
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void (^)(UIImage *))handler {

	BOOL hasHandler = (handler != NULL);

	// If the image exists in the memory cache, use it!
	UIImage *image = [_memoryCache imageForKey:key size:size];
	if (image) {
		if (hasHandler) handler(image);
		return;
	}

	// If the image is in the disk queue to be saved, pull it out and use it
	_DCTImageCacheSaveOperation *diskSaveOperation = [self _operationOfClass:[_DCTImageCacheSaveOperation class] onQueue:_diskQueue withKey:key size:size];
	image = diskSaveOperation.image;
	if (image) {
		if (hasHandler) handler(image);
		return;
	}

	// Check if there's a network fetch in the queue, if there is, a disk fetch is on the disk queue, or failed.
	_DCTImageCacheFetchOperation *networkFetchOperation = [self _operationOfClass:[_DCTImageCacheFetchOperation class] onQueue:_queue withKey:key size:size];

	NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), networkFetchOperation);

	if (!networkFetchOperation) {

		_DCTImageCacheFetchOperation *diskFetchOperation = [[_DCTImageCacheFetchOperation alloc] initWithKey:key size:size block:^(void(^imageHander)(UIImage *image)) {
			UIImage *image = [_diskCache imageForKey:key size:size];
			imageHander(image);
			if (image && hasHandler) [_memoryCache setImage:image forKey:key size:size];
		}];
		diskFetchOperation.queuePriority = NSOperationQueuePriorityVeryHigh;

		networkFetchOperation = [[_DCTImageCacheFetchOperation alloc] initWithKey:key size:size block:^(void(^imageHander)(UIImage *image)) {

			self.imageFetcher(key, size, ^(UIImage *image) {

				if (!image) return;

				imageHander(image);
				if (hasHandler) {
					[_memoryCache setImage:image forKey:key size:size];
				}
				_DCTImageCacheSaveOperation *diskSave = [[_DCTImageCacheSaveOperation alloc] initWithKey:key size:size image:image block:^{
					[_diskCache setImage:image forKey:key size:size];
				}];
				diskSave.queuePriority = NSOperationQueuePriorityVeryLow;
				[_diskQueue addOperation:diskSave];
			});
		}];

		[networkFetchOperation addDependency:diskFetchOperation];
		[_queue addOperation:networkFetchOperation];
		[_diskQueue addOperation:diskFetchOperation];
	}

	if (!hasHandler) return;

	// Create a handler operation to be executed once an operation is finished
	_DCTImageCacheImageOperation *handlerOperation = [[_DCTImageCacheImageOperation alloc] initWithKey:key size:size imageHandler:handler];
	[handlerOperation addDependency:networkFetchOperation];
	[_queue addOperation:handlerOperation];
}

#pragma mark Internal

- (void)_performVeryLowPriorityBlockOnDiskQueue:(void(^)())block {
	NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:block];
	[blockOperation setQueuePriority:NSOperationQueuePriorityVeryLow];
	[_queue addOperation:blockOperation];
}

- (id)_operationOfClass:(Class)class onQueue:(NSOperationQueue *)queue withKey:(NSString *)key size:(CGSize)size {

	__block id returnOperation;

	[queue.operations enumerateObjectsUsingBlock:^(_DCTImageCacheOperation *operation, NSUInteger i, BOOL *stop) {

		if (![operation isKindOfClass:class]) return;

		if (!CGSizeEqualToSize(operation.size, size)) return;
		if (![operation.key isEqualToString:key]) return;

		returnOperation = operation;
		*stop = YES;
	}];

	return returnOperation;
}

- (NSArray *)_operationsOfClass:(Class)class onQueue:(NSOperationQueue *)queue withKey:(NSString *)key size:(CGSize)size {

	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(_DCTImageCacheOperation *operation, NSDictionary *bindings) {
		if (![operation isKindOfClass:class]) return NO;
		if (!CGSizeEqualToSize(operation.size, size)) return NO;
		return [operation.key isEqualToString:key];
	}];

	return [queue.operations filteredArrayUsingPredicate:predicate];
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
