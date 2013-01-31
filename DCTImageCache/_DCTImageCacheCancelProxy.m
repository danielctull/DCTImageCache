//
//  _DCTImageCacheCancelProxy.m
//  DCTImageCache
//
//  Created by Daniel Tull on 08.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheCancelProxy.h"

@interface _DCTImageCacheCancelProxy ()
@property (nonatomic, readwrite, getter = isCancelled) BOOL cancelled;
@property (nonatomic, strong) NSMutableArray *processes;
@end

@implementation _DCTImageCacheCancelProxy

- (id)init {
	self = [super init];
	if (!self) return nil;
	_processes = [NSMutableArray new];
	return self;
}

- (void)cancel {
	self.cancelled = YES;
	[self.processes makeObjectsPerformSelector:@selector(cancel)];
}

- (void)addProcess:(id<DCTImageCacheProcess>)process {
	if (self.cancelled)
		[process cancel];
	else
		[self.processes addObject:process];
}

@end
