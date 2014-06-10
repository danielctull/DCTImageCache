//
//  NSProgress+DCTImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 12.12.2013.
//  Copyright (c) 2013 Daniel Tull. All rights reserved.
//

#import "NSProgress+DCTImageCache.h"

@implementation NSProgress (DCTImageCache)

- (void)dctImageCache_addWrappedBlock:(void(^)())block {
	self.totalUnitCount++;
	[self becomeCurrentWithPendingUnitCount:1];
	block();
	[self resignCurrent];
}

@end
