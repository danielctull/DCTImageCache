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

- (id)initWithPath:(NSString *)path;

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size;
- (id<DCTImageCacheProcess>)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(DCTImageCacheImageHandler)handler;
- (id<DCTImageCacheProcess>)hasImageForKey:(NSString *)key size:(CGSize)size handler:(_DCTImageCacheHasImageHandler)handler;

- (id<DCTImageCacheProcess>)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size;

- (void)removeAllImages;
- (void)removeAllImagesForKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key size:(CGSize)size;

@end
