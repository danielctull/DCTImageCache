//
//  _DCTImageCacheWeakMutableArray.m
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheWeakMutableArray.h"
#import "_DCTImageCacheWeakObject.h"

@implementation _DCTImageCacheWeakMutableArray {
	NSMutableArray *_array;
}

- (id)init {
	self = [super init];
	if (!self) return nil;
	_array = [NSMutableArray new];
	return self;
}

- (NSUInteger)count {
	return _array.count;
}

- (id)objectAtIndex:(NSUInteger)index {
	_DCTImageCacheWeakObject *wrapper = [_array objectAtIndex:index];
	return wrapper.object;
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index {
	_DCTImageCacheWeakObject *wrapper = [[_DCTImageCacheWeakObject alloc] initWithObject:object];
	[_array insertObject:wrapper atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index {
	[_array removeObjectAtIndex:index];
}

- (void)addObject:(id)object {
	_DCTImageCacheWeakObject *wrapper = [[_DCTImageCacheWeakObject alloc] initWithObject:object];
	[_array addObject:wrapper];
}

- (void)removeLastObject {
	[_array removeLastObject];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object {
	_DCTImageCacheWeakObject *wrapper = [[_DCTImageCacheWeakObject alloc] initWithObject:object];
	[_array replaceObjectAtIndex:index withObject:wrapper];
}

@end
