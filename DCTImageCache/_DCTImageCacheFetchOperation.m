//
//  _DCTImageCacheFetchOperation.m
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheFetchOperation.h"

@implementation _DCTImageCacheFetchOperation

- (id)initWithKey:(NSString *)key
			 size:(CGSize)size
			block:(UIImage *(^)())block {
	self = [super initWithKey:key size:size];
	if (!self) return nil;
	_block = block;
	return self;
}

- (void)main {
	_fetchedImage = self.block();
}

@end
