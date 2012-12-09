//
//  _DCTImageCacheCancelManager.m
//  DCTImageCache
//
//  Created by Daniel Tull on 08.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheCancelManager.h"
#import <objc/runtime.h>

@implementation _DCTImageCacheCancelManager {
	NSMutableArray *_proxies;
	__weak id<DCTImageCacheCanceller> _cancelObject;
}

+ (instancetype)cancelManagerForObject:(id<DCTImageCacheCanceller>)cancelObject {

	_DCTImageCacheCancelManager *manager = objc_getAssociatedObject(cancelObject, _cmd);
	if (manager) return manager;

	manager = [[self alloc] initWithCancelObject:cancelObject];
	objc_setAssociatedObject(cancelObject, _cmd, manager, OBJC_ASSOCIATION_RETAIN);
	return manager;
}

- (id)initWithCancelObject:(id<DCTImageCacheCanceller>)cancelObject {
	self = [self init];
	if (!self) return nil;
	_cancelObject = cancelObject;
	_proxies = [NSMutableArray new];
	return self;
}

- (void)addCancelProxy:(_DCTImageCacheCancelProxy *)proxy {
	[_proxies addObject:proxy];
	[proxy addCancelManager:self];
}

- (void)removeCancelProxy:(_DCTImageCacheCancelProxy *)proxy {
	[_proxies removeObject:proxy];

	if (_proxies.count == 0) [_cancelObject cancel];
}

- (void)dealloc {
	[_proxies makeObjectsPerformSelector:@selector(removeCancelManager:) withObject:self];
}

@end
