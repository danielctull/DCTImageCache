//
//  _DCTImageCacheFetcher.m
//  DCTImageCache
//
//  Created by Daniel Tull on 02.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheFetcher.h"
#import "_DCTImageCacheCancelProxy.h"
#import "_DCTImageCacheCompletion.h"

@interface _DCTImageCacheFetcher ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMutableDictionary *handlers;
@end

@implementation _DCTImageCacheFetcher

- (id)init {
	self = [super init];
	if (!self) return nil;
	_queue = [[NSOperationQueue alloc] init];
	_queue.name = NSStringFromClass([self class]);
	_queue.maxConcurrentOperationCount = 1;
	_handlers = [NSMutableDictionary new];
	return self;
}

- (id<DCTImageCacheProcess>)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler {

	NSParameterAssert(attributes);
	NSParameterAssert(handler);

	if (self.imageFetcher == NULL) return nil;

	_DCTImageCacheCancelProxy *cancelProxy = [_DCTImageCacheCancelProxy new];

	[self.queue addOperationWithBlock:^{

		NSMutableArray *handlers = [self handlersForAttributes:attributes];
		[handlers addObject:handler];
		if (handlers.count > 1) return;

		self.imageFetcher(attributes, [[_DCTImageCacheCompletion alloc] initWithHandler:^(UIImage *image, NSError *error) {
			[self.queue addOperationWithBlock:^{

				NSMutableArray *handlers = [self handlersForAttributes:attributes];
				[handlers enumerateObjectsUsingBlock:^(DCTImageCacheImageHandler handler, NSUInteger i, BOOL *stop) {
					handler(image, error);
				}];
			}];
		}]);
	}];
	
	return cancelProxy;
}

- (NSMutableArray *)handlersForAttributes:(DCTImageCacheAttributes *)attributes {
	NSMutableArray *handlers = [self.handlers objectForKey:attributes.identifier];
	if (!handlers) {
		handlers = [NSMutableArray new];
		[self.handlers setObject:handlers forKey:attributes.identifier];
	}
	return handlers;
}

@end
