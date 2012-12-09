//
//  _DCTImageCacheCancelProxy.h
//  DCTImageCache
//
//  Created by Daniel Tull on 08.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_DCTImageCache.h"
@class _DCTImageCacheProcessManager;

@interface _DCTImageCacheCancelProxy : NSObject <DCTImageCacheProcess>

- (void)addProcessManager:(_DCTImageCacheProcessManager *)processManager;
@property (nonatomic, copy) DCTImageCacheImageHandler imageHandler;
@property (nonatomic, copy) _DCTImageCacheHasImageHandler hasImageHandler;

@end
