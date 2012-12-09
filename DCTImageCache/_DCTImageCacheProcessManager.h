//
//  _DCTImageCacheCancelManager.h
//  DCTImageCache
//
//  Created by Daniel Tull on 08.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_DCTImageCacheCancelProxy.h"
#import "DCTImageCache.h"

@interface _DCTImageCacheProcessManager : NSObject <DCTImageCacheCompletion>

+ (instancetype)processManagerForProcess:(id<DCTImageCacheProcess>)process;
@property (nonatomic, weak) id<DCTImageCacheProcess> process;

@property (nonatomic, strong) UIImage *image;

- (void)addCancelProxy:(_DCTImageCacheCancelProxy *)proxy;
- (void)removeCancelProxy:(_DCTImageCacheCancelProxy *)proxy;

@end
