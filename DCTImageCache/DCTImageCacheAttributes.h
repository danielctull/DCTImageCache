//
//  DCTImageCacheAttributes.h
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const DCTImageCacheAttributesKey;
extern NSString *const DCTImageCacheAttributesSize;
extern NSString *const DCTImageCacheAttributesCreatedBefore;

/**
 */
@interface DCTImageCacheAttributes : NSObject

- (id)initWithDictionary:(NSDictionary *)dictionary;
@property (nonatomic, readonly, copy) NSDictionary *dictionary;
@property (nonatomic, readonly) NSString *identifier;

@end
