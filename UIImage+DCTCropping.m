//
//  UIImage+DCTCropping.m
//  Tweetville
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "UIImage+DCTCropping.h"

@implementation UIImage (DCTCropping)

- (UIImage *)dct_imageToFitSize:(CGSize)size {
	
	CGImageRef imageRef = self.CGImage;
	CGFloat height = self.size.height;
	CGFloat width = self.size.width;
	
	if (height < width) {
		NSInteger x = (NSInteger)(width-height)/2.0f;
		imageRef = CGImageCreateWithImageInRect(imageRef, CGRectMake((CGFloat)x, 0.0f, height, height));
		
	} else if (height > width) {
		NSInteger y = (NSInteger)(height-width)/2.0f;
		imageRef = CGImageCreateWithImageInRect(imageRef, CGRectMake(0.0f, y, width, width));
		
	} else {
		CGImageRetain(imageRef);
	}
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaNoneSkipLast);
	
	CGRect imageRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
	
	CGContextSetFillColor(context, CGColorGetComponents([UIColor whiteColor].CGColor));
	CGContextFillRect(context, imageRect);
	
	CGContextDrawImage(context, imageRect, imageRef);
	
	CGImageRef scaledImage = CGBitmapContextCreateImage(context);
	UIImage *image = [UIImage imageWithCGImage:scaledImage];
	
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);
	CGImageRelease(imageRef);
	CGImageRelease(scaledImage);
	
	return image;
}

- (void)dct_generateImageToFitSize:(CGSize)size handler:(void (^)(UIImage *))handler {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		if (handler == NULL) return;
		UIImage *image = [self dct_imageToFitSize:size];
		handler(image);
	});
}

@end
