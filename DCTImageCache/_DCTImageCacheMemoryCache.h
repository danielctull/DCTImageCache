//
//  _DCTMemoryImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTImageCache.h"

@interface _DCTImageCacheMemoryCache : NSObject

- (void)setImage:(UIImage *)image forAttributes:(DCTImageCacheAttributes *)attributes;
- (void)removeAllImages;
- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes;
- (BOOL)hasImageWithAttributes:(DCTImageCacheAttributes *)attributes;
- (UIImage *)imageWithAttributes:(DCTImageCacheAttributes *)attributes;

@end
