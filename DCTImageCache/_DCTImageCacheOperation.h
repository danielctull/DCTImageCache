//
//  _DCTImageCacheOperation.h
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTImageCache.h"

typedef enum : NSInteger {
	_DCTImageCacheOperationTypeNone,
	_DCTImageCacheOperationTypeFetch,
	_DCTImageCacheOperationTypeSet,
	_DCTImageCacheOperationTypeSave,
	_DCTImageCacheOperationTypeHasImage,
	_DCTImageCacheOperationTypeHandler
} _DCTImageCacheOperationType;

@interface _DCTImageCacheOperation : NSOperation

+ (instancetype)saveOperationWithBlock:(void(^)())block;
+ (instancetype)setOperationWithKey:(NSString *)key size:(CGSize)size image:(UIImage *)image block:(void(^)())block;
+ (instancetype)handlerOperationWithKey:(NSString *)key size:(CGSize)size handler:(void(^)(BOOL hasImage, UIImage *image))handler;

+ (instancetype)fetchOperationWithKey:(NSString *)key size:(CGSize)size block:(void(^)(void(^)(UIImage *image)))block;

+ (instancetype)hasImageOperationWithKey:(NSString *)key size:(CGSize)size block:(void(^)(void(^)(BOOL hasImage)))block;

@property (readonly, assign) _DCTImageCacheOperationType type;
@property (readonly, copy) NSString *key;
@property (readonly, assign) CGSize size;
@property (readonly, assign) BOOL hasImage;
@property (readonly, strong) UIImage *image;

- (id<DCTImageCacheCanceller>)addHasImageHandler:(void (^)(BOOL hasImage))handler;
- (id<DCTImageCacheCanceller>)addImageHandler:(void (^)(UIImage *image))handler;

@end
