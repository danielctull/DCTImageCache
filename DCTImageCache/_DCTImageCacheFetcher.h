//
//  _DCTImageCacheFetcher.h
//  DCTImageCache
//
//  Created by Daniel Tull on 02.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTImageCache.h"

@interface _DCTImageCacheFetcher : NSObject
@property (nonatomic, copy) DCTImageCacheFetcher imageFetcher;
- (id<DCTImageCacheProcess>)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler;
@end
