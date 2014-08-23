//
//  DCTImageCacheMockCancel.h
//  DCTImageCache
//
//  Created by Daniel Tull on 03.01.2013.
//  Copyright (c) 2013 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTImageCache.h"

@interface DCTImageCacheMockCancel : NSObject <DCTImageCacheProcess>
@property (nonatomic, copy) void (^cancellationBlock)();
@end