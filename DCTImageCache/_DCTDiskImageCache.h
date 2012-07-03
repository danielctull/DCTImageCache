//
//  _DCTDiskImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DCTImageCache.h"

@interface _DCTDiskImageCache : NSObject <DCTImageCache>
- (id)initWithPath:(NSString *)path;
- (void)fetchAttributesForImageWithKey:(NSString *)key size:(CGSize)size handler:(void (^)(NSDictionary *))handler;
- (void)enumerateKeysUsingBlock:(void (^)(NSString *key, BOOL *stop))block;
- (void)enumerateSizesForKey:(NSString *)key usingBlock:(void (^)(CGSize size, BOOL *stop))block;
@end