//
//  NSOperationQueue+_DCTImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 27.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "NSOperationQueue+_DCTImageCache.h"
#import "_DCTImageCacheOperation.h"

@implementation NSOperationQueue (_DCTImageCache)


- (id)dctImageCache_operationOfType:(_DCTImageCacheOperationType)type {
	__block id returnOperation;

	[self.operations enumerateObjectsUsingBlock:^(_DCTImageCacheOperation *operation, NSUInteger i, BOOL *stop) {
		if (![operation isKindOfClass:[_DCTImageCacheOperation class]]) return;
		if (operation.type != type) return;
		returnOperation = operation;
		*stop = YES;
	}];

	return returnOperation;
}

- (id)dctImageCache_operationOfType:(_DCTImageCacheOperationType)type withKey:(NSString *)key size:(CGSize)size {
	__block id returnOperation;

	[self.operations enumerateObjectsUsingBlock:^(_DCTImageCacheOperation *operation, NSUInteger i, BOOL *stop) {
		if (![operation isKindOfClass:[_DCTImageCacheOperation class]]) return;
		if (operation.type != type) return;
		if (!CGSizeEqualToSize(operation.size, size)) return;
		if (![operation.key isEqualToString:key]) return;
		returnOperation = operation;
		*stop = YES;
	}];

	return returnOperation;
}

- (NSArray *)dctImageCache_operationsOfClass:(Class)class withKey:(NSString *)key size:(CGSize)size {

	NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(_DCTImageCacheOperation *operation, NSDictionary *bindings) {
		if (![operation isKindOfClass:class]) return NO;
		if (!CGSizeEqualToSize(operation.size, size)) return NO;
		return [operation.key isEqualToString:key];
	}];

	return [self.operations filteredArrayUsingPredicate:predicate];
}

@end
