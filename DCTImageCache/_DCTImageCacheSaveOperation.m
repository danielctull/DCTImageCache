//
//  _DCTImageCacheSaveOperation.m
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheSaveOperation.h"

@implementation _DCTImageCacheSaveOperation

- (id)initWithKey:(NSString *)key
			 size:(CGSize)size
			image:(UIImage *)image
			block:(void(^)())block {

	self = [super initWithKey:key size:size];
	if (!self) return nil;
	_image = image;
	_block = block;
	return self;
}

- (void)main {
	self.block();
}

@end
