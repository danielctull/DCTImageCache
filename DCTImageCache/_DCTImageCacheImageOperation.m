//
//  _DCTImageCacheImageOperation.m
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheImageOperation.h"
#import "_DCTImageCacheFetchOperation.h"

@implementation _DCTImageCacheImageOperation

- (id)initWithKey:(NSString *)key
			 size:(CGSize)size
	 imageHandler:(void (^)(UIImage *))imageHandler {

	self = [super initWithKey:key size:size];
	if (!self) return nil;
	_imageHandler = imageHandler;
	return self;
}

- (void)main {
	_DCTImageCacheFetchOperation *operation = [self.dependencies lastObject];
	self.imageHandler(operation.fetchedImage);
}

@end
