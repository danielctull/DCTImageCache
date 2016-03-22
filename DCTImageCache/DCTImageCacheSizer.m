//
//  DCTImageCacheSizer.m
//  DCTImageCache
//
//  Created by Daniel Tull on 12.06.2014.
//  Copyright (c) 2014 Daniel Tull. All rights reserved.
//

@import CoreGraphics;
#import "DCTImageCacheSizer.h"

@implementation DCTImageCacheSizer

- (DCTImageCacheImage *)resizeImage:(DCTImageCacheImage *)image toSize:(CGSize)size contentMode:(DCTImageCacheAttributesContentMode)contentMode {

	if (!image) return nil;

	CGRect imageRect = [self rectForOriginalSize:image.size desiredSize:size contentMode:contentMode];

	CGRect contextRect = CGRectMake(0.0, 0.0, size.width, size.height);
	CGRect intersectionRect = CGRectIntersection(imageRect, contextRect);
	BOOL isOpaque = (CGRectEqualToRect(contextRect, intersectionRect)
					 && ![self imageContainsAlpha:image]);

	return [self performGraphicsContextWorkWithSize:size opaque:isOpaque block:^{
		[image drawInRect:imageRect];
	}];
}

#if TARGET_OS_IPHONE

- (CGImageRef)imageRefFromImage:(UIImage *)image {
	return image.CGImage;
}

- (UIImage *)performGraphicsContextWorkWithSize:(CGSize)size opaque:(BOOL)opaque block:(void(^)())block {
	UIGraphicsBeginImageContextWithOptions(size, opaque, 0.0);
	block();
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

#else

- (NSImage *)performGraphicsContextWorkWithSize:(CGSize)size opaque:(BOOL)opaque block:(void(^)())block {

	NSImage *image = [[NSImage alloc] initWithSize:size];
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																	pixelsWide:size.width
																	pixelsHigh:size.height
																 bitsPerSample:8
															   samplesPerPixel:4
																	  hasAlpha:!opaque
																	  isPlanar:NO
																colorSpaceName:NSCalibratedRGBColorSpace
																   bytesPerRow:0
																  bitsPerPixel:0];
	[image addRepresentation:rep];
	[image lockFocus];
	block();
	[image unlockFocus];
	return image;
}

- (CGImageRef)imageRefFromImage:(DCTImageCacheImage *)image {
	CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)image.TIFFRepresentation, NULL);
	CGImageRef maskRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
	return maskRef;
}

#endif

- (BOOL)imageContainsAlpha:(DCTImageCacheImage *)image {
	CGImageRef imageRef = [self imageRefFromImage:image];
	CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
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
			return CGRectMake(0.0, 0.0, 0.0, 0.0);
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
		return CGRectMake(0.0, y, desiredWidth, newImageHeight);

	} else if (originalRatio > desiredRatio) {
		NSInteger newImageWidth = originalWidth * desiredHeight/originalHeight;
		NSInteger x = (NSInteger)(desiredWidth-newImageWidth)/2.0f;
		return CGRectMake((CGFloat)x, 0.0, (CGFloat)newImageWidth, desiredHeight);
	}

	return CGRectMake(0.0, 0.0, desiredWidth, desiredHeight);
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
		return CGRectMake((CGFloat)x, 0.0, (CGFloat)newImageWidth, desiredHeight);

	} else if (originalRatio > desiredRatio) {
		NSInteger newImageHeight = originalHeight * desiredWidth/originalWidth;
		NSInteger y = (NSInteger)(desiredHeight-newImageHeight)/2.0f;
		return CGRectMake(0.0, y, desiredWidth, newImageHeight);
	}

	return CGRectMake(0.0, 0.0, desiredWidth, desiredHeight);
}

@end
