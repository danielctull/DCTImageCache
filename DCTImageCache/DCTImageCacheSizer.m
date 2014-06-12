//
//  DCTImageCacheSizer.m
//  DCTImageCache
//
//  Created by Daniel Tull on 12.06.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

#import "DCTImageCacheSizer.h"

@implementation DCTImageCacheSizer

- (UIImage *)resizeImage:(DCTImageCacheImage *)image toSize:(CGSize)size contentMode:(DCTImageCacheAttributesContentMode)contentMode {

	if (!image) return nil;

	CGRect imageRect = [self rectForOriginalSize:image.size desiredSize:size contentMode:contentMode];

	CGRect contextRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
	CGRect intersectionRect = CGRectIntersection(imageRect, contextRect);
	BOOL isOpaque = (CGRectEqualToRect(contextRect, intersectionRect)
					 && ![self imageContainsAlpha:image]);

	UIGraphicsBeginImageContextWithOptions(size, isOpaque, 0.0);
	[image drawInRect:imageRect];
	UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return returnImage;
}

- (BOOL)imageContainsAlpha:(DCTImageCacheImage *)image {
	CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image.CGImage);
	if (alphaInfo == kCGImageAlphaNone
		|| alphaInfo == kCGImageAlphaNoneSkipFirst
		||alphaInfo == kCGImageAlphaNoneSkipLast)
		return NO;

	return YES;
}

- (CGRect)rectForOriginalSize:(CGSize)originalSize
				  desiredSize:(CGSize)desiredSize
				  contentMode:(DCTImageCacheAttributesContentMode)contentMode {

	switch (contentMode) {

		case DCTImageCacheAttributesContentModeAspectFit:
			return [self scaleAspectFitRectForOriginalSize:originalSize desiredSize:desiredSize];

		case DCTImageCacheAttributesContentModeAspectFill:
			return [self scaleAspectFillRectForOriginalSize:originalSize desiredSize:desiredSize];

		case DCTImageCacheAttributesContentModeOriginal:
			return CGRectMake(0.0f, 0.0f, 0.0f, 0.0f);
	}
}

- (CGRect)scaleAspectFitRectForOriginalSize:(CGSize)originalSize desiredSize:(CGSize)desiredSize {

	CGFloat originalHeight = originalSize.height;
	CGFloat originalWidth = originalSize.width;
	CGFloat originalRatio = originalHeight/originalWidth;

	CGFloat desiredHeight = desiredSize.height;
	CGFloat desiredWidth = desiredSize.width;
	CGFloat desiredRatio = desiredHeight/desiredWidth;

	if (originalRatio < desiredRatio) {
		NSInteger newImageHeight = originalHeight * desiredWidth/originalWidth;
		NSInteger y = (NSInteger)(desiredHeight-newImageHeight)/2.0f;
		return CGRectMake(0.0f, y, desiredWidth, newImageHeight);

	} else if (originalRatio > desiredRatio) {
		NSInteger newImageWidth = originalWidth * desiredHeight/originalHeight;
		NSInteger x = (NSInteger)(desiredWidth-newImageWidth)/2.0f;
		return CGRectMake((CGFloat)x, 0.0f, (CGFloat)newImageWidth, desiredHeight);
	}

	return CGRectMake(0.0f, 0.0f, desiredWidth, desiredHeight);
}

- (CGRect)scaleAspectFillRectForOriginalSize:(CGSize)originalSize desiredSize:(CGSize)desiredSize {
	CGFloat originalHeight = originalSize.height;
	CGFloat originalWidth = originalSize.width;
	CGFloat originalRatio = originalHeight/originalWidth;

	CGFloat desiredHeight = desiredSize.height;
	CGFloat desiredWidth = desiredSize.width;
	CGFloat desiredRatio = desiredHeight/desiredWidth;

	if (originalRatio < desiredRatio) {
		NSInteger newImageWidth = originalWidth * desiredHeight/originalHeight;
		NSInteger x = (NSInteger)(desiredWidth-newImageWidth)/2.0f;
		return CGRectMake((CGFloat)x, 0.0f, (CGFloat)newImageWidth, desiredHeight);

	} else if (originalRatio > desiredRatio) {
		NSInteger newImageHeight = originalHeight * desiredWidth/originalWidth;
		NSInteger y = (NSInteger)(desiredHeight-newImageHeight)/2.0f;
		return CGRectMake(0.0f, y, desiredWidth, newImageHeight);
	}

	return CGRectMake(0.0f, 0.0f, desiredWidth, desiredHeight);
}

@end
