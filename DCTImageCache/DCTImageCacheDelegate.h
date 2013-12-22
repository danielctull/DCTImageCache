//
//  DCTImageCacheDelegate.h
//  DCTImageCache
//
//  Created by Daniel Tull on 22.12.2013.
//  Copyright (c) 2013 Daniel Tull. All rights reserved.
//

@import Foundation;
@class DCTImageCache;
#import "DCTImageCacheCancellation.h"

@protocol DCTImageCacheDelegate <NSObject>
- (id<DCTImageCacheCancellation>)imageCache:(DCTImageCache *)imageCache fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler;
@end
