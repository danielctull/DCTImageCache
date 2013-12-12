//
//  NSProgress+DCTImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 12.12.2013.
//  Copyright (c) 2013 Daniel Tull. All rights reserved.
//

#import "NSProgress+DCTImageCache.h"

@implementation NSProgress (DCTImageCache)

+ (instancetype)dctImageCache_progressWithParentProgress:(NSProgress *)parentProgress operation:(NSOperation *)operation {

	NSProgress *progress = [[NSProgress alloc] initWithParent:parentProgress userInfo:nil];

	progress.cancellationHandler = ^{
		[operation cancel];
	};
	
	return progress;
}

@end
