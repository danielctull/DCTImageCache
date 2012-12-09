//
//  _DCTImageCacheFetcher.h
//  DCTImageCache
//
//  Created by Daniel Tull on 02.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCTImageCache.h"

@interface _DCTImageCacheFetcher : NSObject
@property (nonatomic, copy) id<DCTImageCacheProcess> (^imageFetcher)(NSString *key, CGSize size, id<DCTImageCacheCompletion> setter);
- (id<DCTImageCacheProcess>)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void(^)(UIImage *))handler;
@end
