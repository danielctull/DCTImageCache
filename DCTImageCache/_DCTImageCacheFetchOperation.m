//
//  _DCTImageCacheFetchOperation.m
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheFetchOperation.h"

@implementation _DCTImageCacheFetchOperation {
	BOOL _isExecuting;
	BOOL _isFinished;
}

- (id)initWithKey:(NSString *)key
			 size:(CGSize)size
			block:(void(^)(void(^)(UIImage *fetchedImage)))block {
	self = [super initWithKey:key size:size];
	if (!self) return nil;
	_block = block;
	return self;
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

- (void)start {

	if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        _isFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }

	_isExecuting = YES;

	__weak _DCTImageCacheFetchOperation *weakSelf = self;
	self.block(^(UIImage *image) {
		_fetchedImage = image;
		[weakSelf willChangeValueForKey:@"isExecuting"];
		[weakSelf willChangeValueForKey:@"isFinished"];
		_isExecuting = NO;
		_isFinished = YES;
		[weakSelf didChangeValueForKey:@"isExecuting"];
		[weakSelf didChangeValueForKey:@"isFinished"];
	});
}

@end
