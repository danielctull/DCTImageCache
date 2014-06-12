//
//  _DCTDiskImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTImageCache+Private.h"

@interface _DCTImageCacheDiskCache : NSObject

- (id)initWithStoreURL:(NSURL *)storeURL;
@property (nonatomic, readonly) NSURL *URL;

- (void)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes
						 handler:(DCTImageCacheImageHandler)handler __attribute__((nonnull(1,2)));

- (void)hasImageWithAttributes:(DCTImageCacheAttributes *)attributes
					   handler:(DCTImageCacheHasImageHandler)handler __attribute__((nonnull(1,2)));

- (void)setImage:(DCTImageCacheImage *)image
   forAttributes:(DCTImageCacheAttributes *)attributes __attribute__((nonnull(1,2)));

- (void)removeAllImages;

- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes __attribute__((nonnull(1)));

@end
