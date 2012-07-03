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
	[imageCache fetchImageForKey:@"http://apod.nasa.gov/apod/image/1207/saturntitan2_cassini_960.jpg" size:CGSizeZero handler:^(UIImage *image) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.imageView.image = image;
		});
	}];
}

@end
