//
//  _DCTImageCacheOperation.h
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTImageCache.h"
#import "_DCTImageCacheProcessManager.h"

typedef enum : NSInteger {
	_DCTImageCacheOperationTypeNone,
	_DCTImageCacheOperationTypeFetch,
	_DCTImageCacheOperationTypeSet,
	_DCTImageCacheOperationTypeSave,
	_DCTImageCacheOperationTypeHasImage,
	_DCTImageCacheOperationTypeHandler
} _DCTImageCacheOperationType;

@interface _DCTImageCacheOperation : NSOperation <DCTImageCacheProcess>

@property (assign) _DCTImageCacheOperationType type;
@property (copy) NSString *key;
@property (assign) CGSize size;

@property (copy) void(^block)();

@end
