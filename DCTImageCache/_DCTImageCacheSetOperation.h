//
//  _DCTImageCacheSetOperation.h
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheOperation.h"
#import "_DCTDiskImageCache.h"

@interface _DCTImageCacheSetOperation : _DCTImageCacheOperation

- (id)initWithKey:(NSString *)key
			 size:(CGSize)size
			image:(UIImage *)image
			block:(void(^)())block;

@property (readonly, copy) void(^block)();
@property (readonly, strong) UIImage *image;

@end
