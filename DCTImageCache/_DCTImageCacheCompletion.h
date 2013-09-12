//
//  _DCTImageCacheCompletion.h
//  DCTImageCache
//
//  Created by Daniel Tull on 31.01.2013.
//  Copyright (c) 2013 Daniel Tull. All rights reserved.
//

#import "DCTImageCache.h"

@interface _DCTImageCacheCompletion : NSObject <DCTImageCacheCompletion>
- (id)initWithHandler:(DCTImageCacheImageHandler)handler;
@property (nonatomic, readonly) DCTImageCacheImageHandler handler;
@end
