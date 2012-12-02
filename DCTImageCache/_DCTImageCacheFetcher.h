//
//  _DCTImageCacheFetcher.h
//  DCTImageCache
//
//  Created by Daniel Tull on 02.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTImageCache.h"

@interface _DCTImageCacheFetcher : NSObject <DCTImageCacheSetter>
@property (nonatomic, copy) id<DCTImageCacheCanceller> (^imageFetcher)(NSString *key, CGSize size, id<DCTImageCacheSetter> setter);
- (id<DCTImageCacheCanceller>)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void(^)(UIImage *))handler;
@end
