//
//  _DCTImageCacheCancelProxy.h
//  DCTImageCache
//
//  Created by Daniel Tull on 08.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTImageCache.h"

@interface _DCTImageCacheCancelProxy : NSObject <DCTImageCacheProcess>

@property (nonatomic, readonly, getter = isCancelled) BOOL cancelled;
- (void)addProcess:(id<DCTImageCacheProcess>)process;

@end
