//
//  _DCTImageCacheCancelManager.m
//  DCTImageCache
//
//  Created by Daniel Tull on 08.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheProcessManager.h"
#import <objc/runtime.h>

@implementation _DCTImageCacheProcessManager {
	NSMutableArray *_proxies;
	NSMutableArray *_handlers;
	__weak id<DCTImageCacheProcess> _process;
}

+ (instancetype)processManagerForProcess:(id<DCTImageCacheProcess>)process {

	_DCTImageCacheProcessManager *manager = objc_getAssociatedObject(process, _cmd);
	if (manager) return manager;

	manager = [[self alloc] initWithProcess:process];
	objc_setAssociatedObject(process, _cmd, manager, OBJC_ASSOCIATION_RETAIN);
	return manager;
}

- (id)initWithProcess:(id<DCTImageCacheProcess>)process {
	self = [self init];
	if (!self) return nil;
	_process = process;
	_proxies = [NSMutableArray new];
	return self;
}

- (void)addCancelProxy:(_DCTImageCacheCancelProxy *)proxy {
	[_proxies addObject:proxy];
	[proxy addProcessManager:self];
}

- (void)removeCancelProxy:(_DCTImageCacheCancelProxy *)proxy {
	[_proxies removeObject:proxy];

	if (_proxies.count == 0) [_process cancel];
}

@end
