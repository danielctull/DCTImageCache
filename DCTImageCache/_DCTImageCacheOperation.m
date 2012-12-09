//
//  _DCTImageCacheOperation.m
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheOperation.h"

NSString * const _DCTImageCacheOperationTypeString[] = {
	@"None",
	@"Fetch",
	@"Set",
	@"Save",
	@"HasImage",
	@"Handler"
};

@implementation _DCTImageCacheOperation

- (void)main {
	self.block();
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; type = %@; key = %@; size = %@>", NSStringFromClass([self class]), self, _DCTImageCacheOperationTypeString[self.type], self.key, NSStringFromCGSize(self.size)];
}

@end
