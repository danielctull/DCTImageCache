//
//  DCTImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef dctimagecache
#define dctimagecache_1_0     10000
#define dctimagecache         dctimagecache_1_0
#endif

@protocol DCTImageCache <NSObject>

- (void)removeAllImages;
- (void)removeAllImagesForKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key size:(CGSize)size;

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size;

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size;
- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size;
- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void(^)(UIImage *image))handler;

@end


@interface DCTImageCache : NSObject <DCTImageCache>

+ (DCTImageCache *)defaultImageCache;

+ (DCTImageCache *)imageCacheWithName:(NSString *)name;
@property (nonatomic, readonly) NSString *name;

@property (nonatomic, copy) void(^imageFetcher)(NSString *key, CGSize size);

@property (nonatomic, readonly) id<DCTImageCache> diskCache;
@property (nonatomic, readonly) id<DCTImageCache> memoryCache;

@end
