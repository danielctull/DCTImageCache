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

+ (instancetype)operationWithType:(_DCTImageCacheOperationType)type onQueue:(NSOperationQueue *)queue {
	__block id returnOperation;

	[queue.operations enumerateObjectsUsingBlock:^(_DCTImageCacheOperation *operation, NSUInteger i, BOOL *stop) {
		if (![operation isKindOfClass:self]) return;
		if (operation.type != type) return;
		returnOperation = operation;
		*stop = YES;
	}];

	return returnOperation;
}

+ (instancetype)operationWithType:(_DCTImageCacheOperationType)type key:(NSString *)key size:(CGSize)size onQueue:(NSOperationQueue *)queue {
	__block id returnOperation;

	[queue.operations enumerateObjectsUsingBlock:^(_DCTImageCacheOperation *operation, NSUInteger i, BOOL *stop) {
		if (![operation isKindOfClass:self]) return;
		if (operation.type != type) return;
		if (!CGSizeEqualToSize(operation.size, size)) return;
		if (![operation.key isEqualToString:key]) return;
		returnOperation = operation;
		*stop = YES;
	}];

	return returnOperation;
}

+ (NSArray *)operationsWithType:(_DCTImageCacheOperationType)type onQueue:(NSOperationQueue *)queue {
	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(_DCTImageCacheOperation *operation, NSDictionary *bindings) {
		if (![operation isKindOfClass:self]) return NO;
		return operation.type == type;
	}];

	return [queue.operations filteredArrayUsingPredicate:predicate];
}

- (void)main {
	self.block();
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; type = %@; key = %@; size = %@>", NSStringFromClass([self class]), self, _DCTImageCacheOperationTypeString[self.type], self.key, NSStringFromCGSize(self.size)];
}

@end
