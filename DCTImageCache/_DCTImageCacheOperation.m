//
//  _DCTImageCacheOperation.m
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheOperation.h"


NSString * const _DCTImageCacheOperationTypeString[] = {
	@"Fetch",
	@"Set",
	@"Save",
	@"HasImage",
	@"Handler"
};

@interface _DCTImageCacheOperation ()
@property (readwrite, assign) _DCTImageCacheOperationType type;
@property (readwrite, copy) NSString *key;
@property (readwrite, assign) CGSize size;
@property (readwrite, strong) UIImage *image;
@property (readwrite, assign) BOOL hasImage;
@property (readwrite, copy) void(^block)();
@end

@interface _DCTImageCacheConcurrentOperation : _DCTImageCacheOperation
@property (readwrite, copy) void(^block)(void(^completion)());
@end

@implementation _DCTImageCacheOperation

+ (instancetype)saveOperationWithBlock:(void(^)())block {
	_DCTImageCacheOperation *operation = [self new];
	operation.type = _DCTImageCacheOperationTypeSave;
	operation.block = block;
	return operation;
}

+ (instancetype)setOperationWithKey:(NSString *)key size:(CGSize)size image:(UIImage *)image block:(void(^)())block {
	_DCTImageCacheOperation *operation = [self new];
	operation.type = _DCTImageCacheOperationTypeSet;
	operation.key = key;
	operation.size = size;
	operation.image = image;
	operation.block = block;
	return operation;
}

+ (instancetype)fetchOperationWithKey:(NSString *)key size:(CGSize)size block:(void(^)(void(^)(UIImage *image)))block {
	_DCTImageCacheConcurrentOperation *operation = [_DCTImageCacheConcurrentOperation new];
	operation.type = _DCTImageCacheOperationTypeFetch;
	operation.key = key;
	operation.size = size;
	operation.block = ^(void(^completion)()) {
		block(^(UIImage *image) {
			operation.hasImage = (image != nil);
			operation.image = image;
			completion();
		});
	};
	return operation;
}

+ (instancetype)hasImageOperationWithKey:(NSString *)key size:(CGSize)size block:(void(^)(void(^)(BOOL hasImage)))block {
	_DCTImageCacheConcurrentOperation *operation = [_DCTImageCacheConcurrentOperation new];
	operation.type = _DCTImageCacheOperationTypeHasImage;
	operation.key = key;
	operation.size = size;
	operation.block = ^(void(^completion)()) {
		block(^(BOOL hasImage) {
			operation.hasImage = hasImage;
			completion();
		});
	};
	return operation;
}

+ (instancetype)handlerOperationWithKey:(NSString *)key size:(CGSize)size handler:(void(^)(BOOL hasImage, UIImage *image))handler {
	_DCTImageCacheOperation *operation = [self new];
	operation.type = _DCTImageCacheOperationTypeHandler;
	operation.key = key;
	operation.size = size;
	operation.block = ^{
		handler(operation.hasImage, operation.image);
	};
	return operation;
}

- (void)main {
	_DCTImageCacheOperation *operation = [self.dependencies lastObject];
	self.image = operation.image;
	self.hasImage = operation.hasImage;
	self.block();
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; type = %@; key = %@; size = %@>", NSStringFromClass([self class]), self, _DCTImageCacheOperationTypeString[self.type], self.key, NSStringFromCGSize(self.size)];
}

@end

@implementation _DCTImageCacheConcurrentOperation  {
	BOOL _isExecuting;
	BOOL _isFinished;
}

- (void)start {

	_DCTImageCacheOperation *operation = [self.dependencies lastObject];
	if (operation.hasImage) {
		self.image = operation.image;
		self.hasImage = operation.hasImage;
		[self cancel];
	}

	if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        _isFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }

	_isExecuting = YES;

	self.block(^() {
		[self willChangeValueForKey:@"isExecuting"];
		[self willChangeValueForKey:@"isFinished"];
		_isExecuting = NO;
		_isFinished = YES;
		[self didChangeValueForKey:@"isExecuting"];
		[self didChangeValueForKey:@"isFinished"];
	});
}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isExecuting {
	return _isExecuting;
}

- (BOOL)isFinished {
	return _isFinished;
}

@end
