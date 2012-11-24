//
//  _DCTImageCacheFetchOperation.h
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheOperation.h"

@interface _DCTImageCacheFetchOperation : _DCTImageCacheOperation

- (id)initWithKey:(NSString *)key
			 size:(CGSize)size
			block:(void(^)(void(^)(UIImage *fetchedImage)))block;

@property (readonly, copy) void(^block)(void(^)(UIImage *fetchedImage));
@property (readonly, strong) UIImage *fetchedImage;

@end
