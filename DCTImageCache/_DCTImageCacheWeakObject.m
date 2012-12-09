//
//  _DCTImageCacheWeakObject.m
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheWeakObject.h"

@implementation _DCTImageCacheWeakObject

- (id)initWithObject:(NSObject *)object {
	self = [self init];
	if (!self) return nil;
	_object = object;
	return self;
}

@end
