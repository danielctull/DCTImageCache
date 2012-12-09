//
//  _DCTImageCacheCancelManager.m
//  DCTImageCache
//
//  Created by Daniel Tull on 08.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheProcessManager.h"
#import <objc/runtime.h>

void* _DCTImageCacheProcessManagerContext = &_DCTImageCacheProcessManagerContext;

@implementation _DCTImageCacheProcessManager {
	NSMutableArray *_proxies;
	NSMutableArray *_handlers;
	__weak id<DCTImageCacheProcess> _process;
}

+ (instancetype)processManagerForProcess:(id<DCTImageCacheProcess>)process {

	if (!process) return nil;

	_DCTImageCacheProcessManager *manager = objc_getAssociatedObject(process, _DCTImageCacheProcessManagerContext);
	if (manager) return manager;

	manager = [self new];
	manager.process = process;
	return manager;
}

- (id)init {
	self = [super init];
	if (!self) return nil;
	_proxies = [NSMutableArray new];
	return self;
}

- (void)setProcess:(id<DCTImageCacheProcess>)process {
	if (_process) objc_setAssociatedObject(_process, _DCTImageCacheProcessManagerContext, nil, OBJC_ASSOCIATION_RETAIN);
	_process = process;
	if (_process) objc_setAssociatedObject(_process, _DCTImageCacheProcessManagerContext, self, OBJC_ASSOCIATION_RETAIN);
}

- (void)addCancelProxy:(_DCTImageCacheCancelProxy *)proxy {
	[_proxies addObject:proxy];
	[proxy addProcessManager:self];
}

- (void)removeCancelProxy:(_DCTImageCacheCancelProxy *)proxy {
	[_proxies removeObject:proxy];

	if (_proxies.count == 0) [_process cancel];
}

- (void)setImage:(UIImage *)image {
	_image = image;
	if (_image) self.hasImage = YES;
}

- (void)dealloc {
	[_proxies enumerateObjectsUsingBlock:^(_DCTImageCacheCancelProxy *proxy, NSUInteger i, BOOL *stop) {
		if (proxy.imageHandler != NULL) proxy.imageHandler(self.image, self.error);
		if (proxy.hasImageHandler != NULL) proxy.hasImageHandler(self.hasImage, self.error);
	}];
}

@end
