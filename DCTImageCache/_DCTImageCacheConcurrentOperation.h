//
//  _DCTImageCacheConcurrentOperation.h
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheOperation.h"

@interface _DCTImageCacheConcurrentOperation : _DCTImageCacheOperation
@property (readwrite, copy) void(^block)(void(^completion)());
@end
