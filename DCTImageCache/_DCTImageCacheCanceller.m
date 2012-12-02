//
//  _DCTImageCacheCanceller.m
//  DCTImageCache
//
//  Created by Daniel Tull on 02.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheCanceller.h"

@implementation _DCTImageCacheCanceller

- (void)cancel {
	[self.handler cancel];
}

@end
