//
//  DCTImageCacheFetcher.m
//  DCTImageCache
//
//  Created by Daniel Tull on 12/06/2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTImageCacheFetcher.h"


@interface DCTImageCacheFetcher ()
@property (nonatomic) NSMutableDictionary *handlers;
@property (nonatomic) NSOperationQueue *queue;
@end

@implementation DCTImageCacheFetcher

- (id)initWithImageCache:(DCTImageCache *)imageCache delegate:(id<DCTImageCacheDelegate>)delegate {
	self = [self init];
	if (!self) return nil;
	_imageCache = imageCache;
	_delegate = delegate;
	_queue = [NSOperationQueue new];
	_queue.maxConcurrentOperationCount = 1;
	return self;
}

- (void)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler {
	[self.queue addOperationWithBlock:^{

		NSArray *handlers = [self handlersForAttributes:attributes];
		BOOL shouldRequest = handlers.count == 0;

		[self addHandler:handler forAttributes:attributes];

		if (!shouldRequest) return;

		[self.delegate imageCache:self.imageCache fetchImageWithAttributes:attributes handler:^(DCTImageCacheImage *image, NSError *error) {
			[self.queue addOperationWithBlock:^{
				for (DCTImageCacheImageHandler handler in handlers) {
					handler(image, error);
				}
				[self removeHandlersForAttributes:attributes];
			}];
		}];
	}];
}

- (NSMutableArray *)handlersForAttributes:(DCTImageCacheAttributes *)attrbutes {

	if (!self.handlers) {
		self.handlers = [NSMutableDictionary new];
	}

	NSMutableArray *handlers = self.handlers[attrbutes];
	if (!handlers) {
		handlers = [NSMutableArray new];
		self.handlers[attrbutes] = handlers;
	}

	return handlers;
}

- (void)addHandler:(DCTImageCacheImageHandler)handler forAttributes:(DCTImageCacheAttributes *)attributes {
	NSMutableArray *handlers = [self handlersForAttributes:attributes];
	[handlers addObject:[handler copy]];
}

- (void)removeHandlersForAttributes:(DCTImageCacheAttributes *)attributes {
	[self.handlers removeObjectForKey:attributes];
}

@end
