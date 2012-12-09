//
//  DCTImageCacheAttributes.m
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTImageCacheAttributes.h"

@implementation DCTImageCacheAttributes {
	NSString *_identifier;
}

- (NSString *)identifier {
	if (!_identifier) _identifier = [NSString stringWithFormat:@"key:%@.size:%@", self.key, NSStringFromCGSize(self.size)];
	return _identifier;
}

@end
