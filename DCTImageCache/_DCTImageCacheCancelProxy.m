//
//  _DCTImageCacheCancelProxy.m
//  DCTImageCache
//
//  Created by Daniel Tull on 08.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheCancelProxy.h"
#import "_DCTImageCacheCancelManager.h"

@implementation _DCTImageCacheCancelProxy

- (void)cancel {
	[self.cancelManager removeCancelProxy:self];
}

@end
