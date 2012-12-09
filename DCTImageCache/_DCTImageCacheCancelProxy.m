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

- (void)addCancelManager:(_DCTImageCacheCancelManager *)cancelManager {
	[_cancelManagers addObject:cancelManager];
}

- (void)cancel {
	[_cancelManagers makeObjectsPerformSelector:@selector(removeCancelProxy:) withObject:self];
}

@end
