//
//  _DCTMemoryImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheMemoryCache.h"

@implementation _DCTImageCacheMemoryCache {
	NSCache *_cache;
}

- (id)init {
    self = [super init];
    if (!self) return nil;
	_cache = [NSCache new];
    return self;
}

- (void)removeAllImages {
	[_cache removeAllObjects];
}

- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes {
	[_cache removeObjectForKey:attributes.identifier];
}

- (void)setImage:(UIImage *)image forAttributes:(DCTImageCacheAttributes *)attributes {
	[_cache setObject:image forKey:attributes.identifier];
}

- (UIImage *)imageWithAttributes:(DCTImageCacheAttributes *)attributes {
	return [_cache objectForKey:attributes.identifier];
}

- (BOOL)hasImageWithAttributes:(DCTImageCacheAttributes *)attributes {
	return ([_cache objectForKey:attributes.identifier] != nil);
}

@end
