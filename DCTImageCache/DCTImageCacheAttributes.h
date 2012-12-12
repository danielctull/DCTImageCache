//
//  DCTImageCacheAttributes.h
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 */
@interface DCTImageCacheAttributes : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, copy) NSDate *createdBefore;

- (NSString *)identifier;

@end
