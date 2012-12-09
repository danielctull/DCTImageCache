//
//  _DCTImageCacheFetcher.m
//  DCTImageCache
//
//  Created by Daniel Tull on 02.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheFetcher.h"
#import "_DCTImageCacheOperation.h"
#import "_DCTImageCacheCancelProxy.h"
#import "_DCTImageCacheWeakMutableDictionary.h"
#import "_DCTImageCacheProcessManager.h"

@implementation _DCTImageCacheFetcher {
	NSOperationQueue *_queue;
	_DCTImageCacheWeakMutableDictionary *_processManagers;
}

- (id)init {
	self = [super init];
	if (!self) return nil;
	_queue = [[NSOperationQueue alloc] init];
	_queue.name = NSStringFromClass([self class]);
	_queue.maxConcurrentOperationCount = 1;
	[_queue addOperationWithBlock:^{
		_processManagers = [_DCTImageCacheWeakMutableDictionary new];
	}];
	return self;
}

- (id<DCTImageCacheProcess>)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void(^)(UIImage *))handler {

	if (self.imageFetcher == NULL) return nil;

	_DCTImageCacheCancelProxy *cancelProxy = [_DCTImageCacheCancelProxy new];
	cancelProxy.imageHandler = handler;

	[_queue addOperationWithBlock:^{

		NSString *accessKey = [NSString stringWithFormat:@"%@.%@", key, NSStringFromCGSize(size)];
		_DCTImageCacheProcessManager *manager = [_processManagers objectForKey:accessKey];

		if (!manager) {
			manager = [_DCTImageCacheProcessManager new];
			manager.process = self.imageFetcher(key, size, manager);
			[_processManagers setObject:manager forKey:accessKey];
		}

		[manager addCancelProxy:cancelProxy];
	}];

	return cancelProxy;
}

@end
