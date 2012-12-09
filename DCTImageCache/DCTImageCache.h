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



@protocol DCTImageCacheProcess <NSObject>
- (void)cancel;
@end



@protocol DCTImageCacheCompletion <NSObject>
- (void)setImage:(UIImage *)image;
- (void)setError:(NSError *)error;
@end



typedef void (^DCTImageCacheImageHandler)(UIImage *, NSError *);

typedef id<DCTImageCacheProcess> (^DCTImageCacheFetcher)(NSString *key, CGSize size, id<DCTImageCacheCompletion> completion);



@interface DCTImageCache : NSObject

+ (DCTImageCache *)defaultImageCache;

+ (DCTImageCache *)imageCacheWithName:(NSString *)name;
@property (nonatomic, readonly) NSString *name;

@property (nonatomic, copy) DCTImageCacheFetcher imageFetcher;

- (void)removeAllImages;
- (void)removeAllImagesForKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key size:(CGSize)size;

- (void)prefetchImageForKey:(NSString *)key size:(CGSize)size;
- (id<DCTImageCacheProcess>)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(DCTImageCacheImageHandler)handler;

@end
