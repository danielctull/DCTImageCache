//
//  _DCTDiskImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "_DCTImageCache.h"

@interface _DCTImageCacheDiskCache : NSObject

- (id)initWithStoreURL:(NSURL *)storeURL;
@property (nonatomic, readonly) NSURL *storeURL;

- (id<DCTImageCacheProcess>)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler __attribute__((nonnull(1,2)));
- (id<DCTImageCacheProcess>)hasImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(_DCTImageCacheHasImageHandler)handler __attribute__((nonnull(1,2)));

- (void)setImage:(UIImage *)image forAttributes:(DCTImageCacheAttributes *)attributes __attribute__((nonnull(1,2)));

- (void)removeAllImages;
- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes;

@end
