//
//  NSProgress+DCTImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 12.12.2013.
//  Copyright (c) 2013 Daniel Tull. All rights reserved.
//

#import "NSProgress+DCTImageCache.h"

@implementation NSProgress (DCTImageCache)

- (instancetype)dctImageCache_progressWithOperation:(NSOperation *)operation {

	NSProgress *progress = [NSProgress new];
	progress.cancellationHandler = ^{
		[operation cancel];
	};
	
	return progress;
}

@end
