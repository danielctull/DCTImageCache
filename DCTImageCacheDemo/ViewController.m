//
//  ViewController.m
//  DCTImageCaccheDemo
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "ViewController.h"
#import <DCTImageCache/DCTImageCache.h>

@interface ViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	DCTImageCache *imageCache = [DCTImageCache defaultImageCache];

	CGFloat width = self.imageView.contentScaleFactor * self.imageView.bounds.size.width;
	CGFloat height = self.imageView.contentScaleFactor * self.imageView.bounds.size.height;

	DCTImageCacheAttributes *attributes = [DCTImageCacheAttributes new];
	attributes.key = @"http://apod.nasa.gov/apod/image/1207/saturntitan2_cassini_960.jpg";
	attributes.size = CGSizeMake(width, height);
	
	[imageCache fetchImageWithAttributes:attributes handler:^(UIImage *image, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.imageView.image = image;
		});
	}];
}

@end
