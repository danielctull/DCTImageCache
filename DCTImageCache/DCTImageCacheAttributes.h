//
//  DCTImageCacheAttributes.h
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

@import Foundation;
@import CoreGraphics;



typedef NS_ENUM(NSInteger, DCTImageCacheAttributesContentMode) {
    DCTImageCacheAttributesContentModeOriginal,
    DCTImageCacheAttributesContentModeAspectFit,
    DCTImageCacheAttributesContentModeAspectFill
};

extern CGSize const DCTImageCacheAttributesSizeNull;

/**
 */
@interface DCTImageCacheAttributes : NSObject <NSCopying>

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSDate *createdBefore;
@property (nonatomic) CGSize size;
@property (nonatomic) CGFloat scale;
@property (nonatomic) DCTImageCacheAttributesContentMode contentMode;

@property (nonatomic, readonly) NSString *sizeString;

@end
