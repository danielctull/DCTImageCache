//
//  NSProgress+DCTImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 12.12.2013.
//  Copyright (c) 2013 Daniel Tull. All rights reserved.
//

@import Foundation;

@interface NSProgress (DCTImageCache)

+ (instancetype)dctImageCache_progressWithParentProgress:(NSProgress *)progress operation:(NSOperation *)operation;

@end
