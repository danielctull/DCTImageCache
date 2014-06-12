//
//  DCTImageCacheSizer.h
//  DCTImageCache
//
//  Created by Daniel Tull on 12.06.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTImageCache+Private.h"

@interface DCTImageCacheSizer : NSObject

- (UIImage *)resizeImage:(DCTImageCacheImage *)image
				  toSize:(CGSize)size
			 contentMode:(DCTImageCacheAttributesContentMode)contentMode;

@end
