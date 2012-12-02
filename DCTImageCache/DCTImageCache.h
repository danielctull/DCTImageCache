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


@protocol DCTImageCacheHandler <NSObject>
- (void)cancel;
@end


@interface DCTImageCache : NSObject

+ (DCTImageCache *)defaultImageCache;

+ (DCTImageCache *)imageCacheWithName:(NSString *)name;
@property (nonatomic, readonly) NSString *name;

@property (nonatomic, copy) void(^imageFetcher)(NSString *key, CGSize size);
- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size;

- (void)removeAllImages;
- (void)removeAllImagesForKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key size:(CGSize)size;

- (void)prefetchImageForKey:(NSString *)key size:(CGSize)size;
- (id<DCTImageCacheHandler>)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void(^)(UIImage *))handler;

@end
