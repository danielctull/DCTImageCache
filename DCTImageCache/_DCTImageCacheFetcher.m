//
//  _DCTImageCacheFetcher.m
//  DCTImageCache
//
//  Created by Daniel Tull on 02.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheFetcher.h"
#import "_DCTImageCacheOperation.h"
#import "NSOperationQueue+_DCTImageCache.h"
#import "_DCTImageCacheCancelProxy.h"
#import "_DCTImageCacheWeakMutableDictionary.h"

@implementation _DCTImageCacheFetcher {
	NSOperationQueue *_queue;
	_DCTImageCacheWeakMutableDictionary *_cancelObjects;
	NSMutableDictionary *_handlers;
}

- (id)init {
	self = [super init];
	if (!self) return nil;
	_queue = [[NSOperationQueue alloc] init];
	_queue.name = NSStringFromClass([self class]);
	_queue.maxConcurrentOperationCount = 1;
	[_queue addOperationWithBlock:^{
		_handlers = [NSMutableDictionary new];
		_cancelObjects = [_DCTImageCacheWeakMutableDictionary new];
	}];
	return self;
}

- (id<DCTImageCacheCanceller>)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void(^)(UIImage *))handler {

	if (self.imageFetcher == NULL) return nil;

	_DCTImageCacheCancelProxy *cancelProxy = [_DCTImageCacheCancelProxy new];

	[_queue addOperationWithBlock:^{

		if (handler != NULL) {
			NSMutableArray *handlers = [self _handlersForKey:key size:size];
			[handlers addObject:handler];
		}

		NSString *accessKey = [self _accessKeyForKey:key size:size];
		id<DCTImageCacheCanceller> networkFetchCancelObject = [_cancelObjects objectForKey:accessKey];

		if (!networkFetchCancelObject)
			networkFetchCancelObject = self.imageFetcher(key, size, self);

		[cancelProxy addCancelObject:networkFetchCancelObject];
	}];

	return cancelProxy;
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	[_queue addOperationWithBlock:^{
		NSArray *handlers = [self _handlersForKey:key size:size];
		[handlers enumerateObjectsUsingBlock:^(void(^handler)(UIImage *), NSUInteger idx, BOOL *stop) {
			handler(image);
		}];
		NSString *accessKey = [self _accessKeyForKey:key size:size];
		[_handlers removeObjectForKey:accessKey];
	}];
}

- (NSMutableArray *)_handlersForKey:(NSString *)key size:(CGSize)size {
	NSString *accessKey = [self _accessKeyForKey:key size:size];
	NSMutableArray *handlers = [_handlers objectForKey:accessKey];
	if (!handlers) {
		handlers = [NSMutableArray new];
		[_handlers setObject:handlers forKey:accessKey];
	}
	return handlers;
}

- (NSString *)_accessKeyForKey:(NSString *)key size:(CGSize)size {
	return [NSString stringWithFormat:@"%@.%@", key, NSStringFromCGSize(size)];
}


@end
