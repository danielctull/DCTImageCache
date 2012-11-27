//
//  _DCTDiskImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "_DCTImageCacheOperation.h"

@interface _DCTDiskImageCache : NSObject

- (id)initWithPath:(NSString *)path;

- (_DCTImageCacheOperation *)setImageOperationWithKey:(NSString *)key size:(CGSize)size;
- (_DCTImageCacheOperation *)setImageOperationWithImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size;

- (_DCTImageCacheOperation *)fetchImageOperationForKey:(NSString *)key size:(CGSize)size;
- (_DCTImageCacheOperation *)hasImageOperationForKey:(NSString *)key size:(CGSize)size;

- (void)removeAllImages;
- (void)removeAllImagesForKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key size:(CGSize)size;

@end
