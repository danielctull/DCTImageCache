//
//  DCTImageCache+Private.h
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTImageCache.h"

#if TARGET_OS_IPHONE
typedef UIImage DCTImageCacheImage;
#else
typedef NSImage DCTImageCacheImage;
#endif

typedef void (^DCTImageCacheHasImageHandler)(BOOL, NSError *);

@interface DCTImageCache (Private)
+ (NSBundle *)bundle;
@end
