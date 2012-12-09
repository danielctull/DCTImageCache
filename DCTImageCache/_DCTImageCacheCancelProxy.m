//
//  _DCTImageCacheCancelProxy.m
//  DCTImageCache
//
//  Created by Daniel Tull on 08.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheCancelProxy.h"
#import "_DCTImageCacheCancelManager.h"
#import "_DCTImageCacheWeakMutableArray.h"

@implementation _DCTImageCacheCancelProxy {
	_DCTImageCacheWeakMutableArray *_cancelManagers;
}

- (id)init {
	self = [super init];
	if (!self) return nil;
	_cancelManagers = [_DCTImageCacheWeakMutableArray new];
	return self;
}

- (void)addCancelObject:(id<DCTImageCacheCanceller>)cancelObject {
	_DCTImageCacheCancelManager *manager = [_DCTImageCacheCancelManager cancelManagerForObject:cancelObject];
	[_cancelManagers addObject:manager];
	[manager addCancelProxy:self];
}

- (void)cancel {
	[_cancelManagers makeObjectsPerformSelector:@selector(removeCancelProxy:) withObject:self];
}

@end
