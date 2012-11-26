//
//  _DCTImageCacheAverager.m
//  DCTImageCache
//
//  Created by Daniel Tull on 26.11.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheAverager.h"

@implementation _DCTImageCacheAverager {
	NSInteger _count;
	double _total;
}

- (void)addTimeInterval:(NSTimeInterval)timeInterval {
	_count++;
	_total += timeInterval;
	NSLog(@"Adding time interval:%@; count:%i; total:%@; average:%@", @(timeInterval), _count, @(_total), @(_total/_count));
}

@end
