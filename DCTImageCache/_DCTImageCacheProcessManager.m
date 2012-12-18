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
	BOOL _finished;
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
	if (_finished) {
		[self callProxy:proxy];
		return;
	}
	[_proxies addObject:proxy];
	[proxy addProcessManager:self];
}

- (void)removeCancelProxy:(_DCTImageCacheCancelProxy *)proxy {
	[_proxies removeObject:proxy];

	if (_proxies.count == 0) [_process cancel];
}

- (void)finishWithHasImage:(BOOL)hasImage error:(NSError *)error {
	if (_finished) return;
	_finished = YES;
	_error = error;
	_hasImage = hasImage;
	[self callProxies];
}

- (void)finishWithImage:(UIImage *)image error:(NSError *)error {
	if (_finished) return;
	_finished = YES;
	_error = error;
	_image = image;
	_hasImage = (_image != nil);
	[self callProxies];
}

- (void)finishWithError:(NSError *)error {
	if (_finished) return;
	_finished = YES;
	_error = error;
	[self callProxies];
}

- (void)callProxies {
	[_proxies enumerateObjectsUsingBlock:^(_DCTImageCacheCancelProxy *proxy, NSUInteger i, BOOL *stop) {
		[self callProxy:proxy];
	}];
}

- (void)callProxy:(_DCTImageCacheCancelProxy *)proxy {
	if (proxy.handler != NULL) proxy.handler(self.error);
	if (proxy.imageHandler != NULL) proxy.imageHandler(self.image, self.error);
	if (proxy.hasImageHandler != NULL) proxy.hasImageHandler(self.hasImage, self.error);
}

@end
