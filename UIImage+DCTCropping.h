//
//  UIImage+DCTCropping.h
//  Tweetville
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (DCTCropping)
- (UIImage *)dct_imageToFitSize:(CGSize)size;
@end
