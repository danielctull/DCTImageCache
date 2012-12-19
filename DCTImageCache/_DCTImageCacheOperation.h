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
	_DCTImageCacheOperationTypeHasImage,
	_DCTImageCacheOperationTypeHandler
} _DCTImageCacheOperationType;

@interface _DCTImageCacheOperation : NSOperation <DCTImageCacheProcess>

+ (instancetype)operationWithType:(_DCTImageCacheOperationType)type onQueue:(NSOperationQueue *)queue;
+ (instancetype)operationWithType:(_DCTImageCacheOperationType)type attributes:(DCTImageCacheAttributes *)attibutes onQueue:(NSOperationQueue *)queue;
+ (NSArray *)operationsWithType:(_DCTImageCacheOperationType)type onQueue:(NSOperationQueue *)queue;


@property (assign) _DCTImageCacheOperationType type;
@property (copy) NSString *uniqueIdentifier;

@property (copy) void(^block)();

@end
