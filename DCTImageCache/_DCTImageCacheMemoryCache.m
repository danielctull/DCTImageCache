//
//  _DCTMemoryImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheMemoryCache.h"

@interface _DCTImageCacheMemoryCache ()
@property (nonatomic, strong) NSCache *cache;
@end

@implementation _DCTImageCacheMemoryCache

- (id)init {
    self = [super init];
    if (!self) return nil;
	_cache = [NSCache new];
    return self;
}

- (void)removeAllImages {
	[self.cache removeAllObjects];
}

- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes {
	[self.cache removeObjectForKey:attributes.identifier];
}

- (void)setImage:(UIImage *)image forAttributes:(DCTImageCacheAttributes *)attributes {
	[self.cache setObject:image forKey:attributes.identifier];
}

- (UIImage *)imageWithAttributes:(DCTImageCacheAttributes *)attributes {
	return [self.cache objectForKey:attributes.identifier];
}

- (BOOL)hasImageWithAttributes:(DCTImageCacheAttributes *)attributes {
	return ([self.cache objectForKey:attributes.identifier] != nil);
}

@end
