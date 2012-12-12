//
//  _DCTImageCacheAttributes.h
//  DCTImageCache
//
//  Created by Daniel Tull on 12.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTImageCacheAttributes.h"
#import "_DCTImageCacheItem.h"

@interface DCTImageCacheAttributes (Private)

- (NSFetchRequest *)_fetchRequest;
- (void)_setupCacheItemProperties:(_DCTImageCacheItem *)cacheItem;

@end
