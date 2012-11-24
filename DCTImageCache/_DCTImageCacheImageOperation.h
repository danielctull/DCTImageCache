//
//  _DCTImageCacheImageOperation.h
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheOperation.h"

@interface _DCTImageCacheImageOperation : _DCTImageCacheOperation

- (id)initWithKey:(NSString *)key
			 size:(CGSize)size
	 imageHandler:(void (^)(UIImage *))imageHandler;

@property (copy, readonly) void (^imageHandler)(UIImage *);

@end
