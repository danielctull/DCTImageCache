//
//  _DCTImageCacheCancelProxy.m
//  DCTImageCache
//
//  Created by Daniel Tull on 08.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheCancelProxy.h"
#import "_DCTImageCacheProcessManager.h"
#import "_DCTImageCacheWeakMutableArray.h"

@implementation _DCTImageCacheCancelProxy {
	_DCTImageCacheWeakMutableArray *_processManagers;
}

- (id)init {
	self = [super init];
	if (!self) return nil;
	_processManagers = [_DCTImageCacheWeakMutableArray new];
	return self;
}

- (void)addProcessManager:(_DCTImageCacheProcessManager *)processManager {
	[_processManagers addObject:processManager];
}

- (void)cancel {
	self.imageHandler = NULL;
	self.hasImageHandler = NULL;
	[_processManagers makeObjectsPerformSelector:@selector(removeCancelProxy:) withObject:self];
}

@end
