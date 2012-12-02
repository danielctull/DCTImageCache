//
//  NSOperationQueue+_DCTImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 27.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "_DCTImageCacheOperation.h"

@interface NSOperationQueue (_DCTImageCache)

- (id)dctImageCache_operationOfType:(_DCTImageCacheOperationType)type;
- (id)dctImageCache_operationOfType:(_DCTImageCacheOperationType)type withKey:(NSString *)key size:(CGSize)size;

- (NSArray *)dctImageCache_operationsOfType:(_DCTImageCacheOperationType)type;

@end
