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
@property (nonatomic, copy, readonly) NSURL *storeURL;

- (UIImage *)imageWithAttributes:(DCTImageCacheAttributes *)attributes;
- (id<DCTImageCacheProcess>)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler;
- (id<DCTImageCacheProcess>)hasImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(_DCTImageCacheHasImageHandler)handler;

- (id<DCTImageCacheProcess>)setImage:(UIImage *)image forAttributes:(DCTImageCacheAttributes *)attributes;

- (void)removeAllImages;
- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes;

@end
