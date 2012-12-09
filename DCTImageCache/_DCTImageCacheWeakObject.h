//
//  _DCTImageCacheWeakObject.h
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface _DCTImageCacheWeakObject : NSObject
- (id)initWithObject:(NSObject *)object;
@property (weak, readonly) id object;
@end
