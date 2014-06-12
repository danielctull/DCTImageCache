//
//  DCTImageCacheFetcher.h
//  DCTImageCache
//
//  Created by Daniel Tull on 12/06/2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import Foundation;
#import "DCTImageCache+Private.h"

@interface DCTImageCacheFetcher : NSObject

- (id)initWithImageCache:(DCTImageCache *)imageCache delegate:(id<DCTImageCacheDelegate>)delegate;

@property (nonatomic, weak) DCTImageCache *imageCache;
@property (nonatomic, weak) id<DCTImageCacheDelegate> delegate;

- (void)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler;

@end
