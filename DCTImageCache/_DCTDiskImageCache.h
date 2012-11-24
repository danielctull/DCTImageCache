//
//  _DCTDiskImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTImageCache.h"

@interface _DCTDiskImageCache : NSObject
- (id)initWithPath:(NSString *)path;

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size;
- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size;

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size;

- (void)removeAllImages;
- (void)removeAllImagesForKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key size:(CGSize)size;

/*- (void)fetchAttributesForImageWithKey:(NSString *)key size:(CGSize)size handler:(void (^)(NSDictionary *))handler;
- (void)enumerateKeysUsingBlock:(void (^)(NSString *key, BOOL *stop))block;
- (void)enumerateSizesForKey:(NSString *)key usingBlock:(void (^)(CGSize size, BOOL *stop))block;
*/@end