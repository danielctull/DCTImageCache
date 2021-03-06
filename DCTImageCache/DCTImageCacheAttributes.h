//
//  DCTImageCacheAttributes.h
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

@import Foundation;
@import CoreGraphics;

extern NSString *const DCTImageCacheAttributesKey;
extern NSString *const DCTImageCacheAttributesSize;
extern NSString *const DCTImageCacheAttributesCreatedBefore;

id DCTImageCacheAttributesObjectForSize(CGSize);

/**
 */
@interface DCTImageCacheAttributes : NSObject

- (id)initWithDictionary:(NSDictionary *)dictionary;
@property (nonatomic, readonly) NSDictionary *dictionary;

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSDate *createdBefore;
@property (nonatomic, readonly) CGSize size;

@property (nonatomic, readonly) NSString *identifier;

@end
