//
//  DCTImageCacheMockCancel.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.01.2013.
//  Copyright (c) 2013 Daniel Tull. All rights reserved.
//

#import "DCTImageCacheMockCancel.h"

@implementation DCTImageCacheMockCancel
- (void)cancel {
	self.cancellationBlock();
}
@end