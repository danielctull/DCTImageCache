//
//  _DCTImageCacheCompletion.m
//  DCTImageCache
//
//  Created by Daniel Tull on 31.01.2013.
//  Copyright (c) 2013 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheCompletion.h"

@implementation _DCTImageCacheCompletion

- (id)initWithHandler:(DCTImageCacheImageHandler)handler {
	NSParameterAssert(handler);
	self = [self init];
	if (!self) return nil;
	_handler = [handler copy];
	return self;
}

- (void)finishWithImage:(DCTImageCacheImage *)image error:(NSError *)error {
	self.handler(image, error);
}

@end
