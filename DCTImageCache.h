//
//  DCTImageCache.h
//  Tweetville
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCTImageCache : NSObject

+ (DCTImageCache *)defaultImageCache;

- (id)initWithName:(NSString *)name;
@property (nonatomic, readonly) NSString *name;

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size;

// The handler is called back on the main queue.
- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void(^)(UIImage *))handler;

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size queue:(dispatch_queue_t)queue handler:(void (^)(UIImage *))handler;

@property (nonatomic, copy) void(^imageFetcher)(NSString *key, CGSize size, void(^imageBlock)(UIImage *));

@end
