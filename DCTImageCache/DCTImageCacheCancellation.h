//
//  DCTImageCacheCancellation.h
//  DCTImageCache
//
//  Created by Daniel Tull on 22.12.2013.
//  Copyright (c) 2013 Daniel Tull. All rights reserved.
//

@import Foundation;

// An object that can be cancelled
@protocol DCTImageCacheCancellation <NSObject>
- (void)cancel;
@end

@interface NSURLConnection (DCTImageCacheCancellation) <DCTImageCacheCancellation>
@end

@interface NSOperation (DCTImageCacheCancellation) <DCTImageCacheCancellation>
@end

@interface NSURLSessionTask (DCTImageCacheCancellation) <DCTImageCacheCancellation>
@end

@interface NSProgress (DCTImageCacheCancellation) <DCTImageCacheCancellation>
@end
