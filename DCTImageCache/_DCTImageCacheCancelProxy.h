//
//  _DCTImageCacheCancelProxy.h
//  DCTImageCache
//
//  Created by Daniel Tull on 08.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTImageCache.h"
@class _DCTImageCacheCancelManager;

@interface _DCTImageCacheCancelProxy : NSObject <DCTImageCacheCanceller>
- (void)addCancelManager:(_DCTImageCacheCancelManager *)cancelManager;
@end
