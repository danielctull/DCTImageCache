//
//  _DCTImageCacheOperation.m
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheOperation.h"

@implementation _DCTImageCacheOperation

- (id)initWithKey:(NSString *)key size:(CGSize)size {
	self = [super init];
	if (!self) return nil;
	_key = [key copy];
	_size = size;
	return self;
}

@end
