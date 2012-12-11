//
//  _DCTImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTImageCache.h"

typedef void (^_DCTImageCacheHasImageHandler)(BOOL, NSError *);

@interface DCTImageCache (Private)
+ (NSBundle *)_bundle;
@end
