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

@property (nonatomic, readonly, assign) BOOL hasImage;
@property (nonatomic, readonly, strong) UIImage *image;
@property (nonatomic, readonly, strong) NSError *error;

- (void)finishWithError:(NSError *)error;
- (void)finishWithHasImage:(BOOL)hasImage error:(NSError *)error;

- (void)addCancelProxy:(_DCTImageCacheCancelProxy *)proxy;
- (void)removeCancelProxy:(_DCTImageCacheCancelProxy *)proxy;

@end
