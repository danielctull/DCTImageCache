//
//  DCTImageCache.h
//  Tweetville
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DCTImageCache : NSObject

+ (DCTImageCache *)defaultImageCache;

+ (DCTImageCache *)imageCacheWithName:(NSString *)name;
@property (nonatomic, readonly) NSString *name;

- (void)removeAllImages;
- (void)removeAllImagesForKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key size:(CGSize)size;

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size;
- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void(^)(UIImage *))handler;

@property (nonatomic, copy) void(^imageFetcher)(NSString *key, CGSize size, void(^imageBlock)(UIImage *));

@end
