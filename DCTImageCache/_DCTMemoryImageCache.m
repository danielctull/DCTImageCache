//
//  _DCTMemoryImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTMemoryImageCache.h"

@implementation _DCTMemoryImageCache {
	__strong NSCache *_cache;
	__strong NSMutableDictionary *_cacheKeys;
}

- (id)init {
    self = [super init];
    if (!self) return nil;
	_cache = [NSCache new];
	_cacheKeys = [NSMutableDictionary new];
    return self;
}

- (void)removeAllImages {
	[_cache removeAllObjects];
}

- (void)removeAllImagesForKey:(NSString *)key {
	[[self _cacheKeysForKey:key] enumerateObjectsUsingBlock:^(NSString *cacheKey, NSUInteger idx, BOOL *stop) {
		[_cache removeObjectForKey:cacheKey];
	}];
}

- (void)removeImageForKey:(NSString *)key size:(CGSize)size {
	NSString *cacheKey = [self _cacheNameForKey:key size:size];
	[[self _cacheKeysForKey:key] removeObject:cacheKey];
	[_cache removeObjectForKey:cacheKey];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	NSString *cacheKey = [self _cacheNameForKey:key size:size];
	[[self _cacheKeysForKey:key] addObject:cacheKey];
	[_cache setObject:image forKey:cacheKey];
}

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size {
	NSString *cacheKey = [self _cacheNameForKey:key size:size];
	return [_cache objectForKey:cacheKey];
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void(^)(UIImage *))handler {
	
	if (handler == NULL) return;
	
	handler([self imageForKey:key size:size]);
}

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size {
	NSString *cacheKey = [self _cacheNameForKey:key size:size];
	return ([_cache objectForKey:cacheKey] != nil);
}

#pragma mark - Internal

- (NSMutableArray *)_cacheKeysForKey:(NSString *)key {
	NSMutableArray *array = [_cacheKeys objectForKey:key];
	if (!array) {
		array = [NSMutableArray new];
		[_cacheKeys setObject:array forKey:key];
	}
	return array;
}

- (NSString *)_cacheNameForKey:(NSString *)key size:(CGSize)size {
	return [NSString stringWithFormat:@"%@.%@", key, NSStringFromCGSize(size)];
}

@end
