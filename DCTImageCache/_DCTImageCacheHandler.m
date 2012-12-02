//
//  _DCTImageCacheHandler.m
//  DCTImageCache
//
//  Created by Daniel Tull on 02.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheHandler.h"

@implementation _DCTImageCacheHandler

- (void)cancel {
	[self.handler cancel];
}

@end
