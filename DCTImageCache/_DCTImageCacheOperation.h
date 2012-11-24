//
//  _DCTImageCacheOperation.h
//  DCTImageCache
//
//  Created by Daniel Tull on 24.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface _DCTImageCacheOperation : NSOperation

- (id)initWithKey:(NSString *)key size:(CGSize)size;
@property (readonly, copy) NSString *key;
@property (readonly, assign) CGSize size;

@end
