//
//  _DCTImageCacheFetcher.h
//  DCTImageCache
//
//  Created by Daniel Tull on 02.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTImageCache.h"

@interface _DCTImageCacheFetcher : NSObject
@property (nonatomic, copy) DCTImageCacheFetcher imageFetcher;
- (NSProgress *)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes parentProgress:(NSProgress *)parentProgress handler:(DCTImageCacheImageHandler)handler __attribute__((nonnull(1,2)));
@end
