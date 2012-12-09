//
//  _DCTImageCacheWeakMutableDictionary.m
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheWeakMutableDictionary.h"
#import "_DCTImageCacheWeakObject.h"

@implementation _DCTImageCacheWeakMutableDictionary {
	NSMutableDictionary *_dictionary;
}

- (id)init {
	self = [super init];
	if (!self) return nil;
	_dictionary = [NSMutableDictionary new];
	return self;
}

- (id)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys {
	self = [self init];
	if (!self) return nil;

	NSMutableArray *wrappedObjects = [[NSMutableArray alloc] initWithCapacity:objects.count];
	[objects enumerateObjectsUsingBlock:^(id object, NSUInteger i, BOOL *stop) {
		_DCTImageCacheWeakObject *wrapper = [[_DCTImageCacheWeakObject alloc] initWithObject:object];
		[wrappedObjects addObject:wrapper];
	}];

	_dictionary = [[NSMutableDictionary alloc] initWithObjects:wrappedObjects forKeys:keys];

	return self;
}

- (NSUInteger)count {
	return _dictionary.count;
}

- (id)objectForKey:(id)key {
	_DCTImageCacheWeakObject *wrapper = [_dictionary objectForKey:key];
	return wrapper.object;
}

- (NSEnumerator *)keyEnumerator {
	return _dictionary.keyEnumerator;
}

- (void)setObject:(id)object forKey:(id<NSCopying>)key {
	_DCTImageCacheWeakObject *wrapper = [[_DCTImageCacheWeakObject alloc] initWithObject:object];
	[_dictionary setObject:wrapper forKey:key];
}

- (void)removeObjectForKey:(id)key {
	[_dictionary removeObjectForKey:key];
}

@end
