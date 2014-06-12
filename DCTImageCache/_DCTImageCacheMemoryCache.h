//
//  _DCTMemoryImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTImageCache+Private.h"

@interface _DCTImageCacheMemoryCache : NSObject

- (void)setImage:(DCTImageCacheImage *)image forAttributes:(DCTImageCacheAttributes *)attributes;
- (void)removeAllImages;
- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes;
- (BOOL)hasImageWithAttributes:(DCTImageCacheAttributes *)attributes;
- (DCTImageCacheImage *)imageWithAttributes:(DCTImageCacheAttributes *)attributes;

@end
