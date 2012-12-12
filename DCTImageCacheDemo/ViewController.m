//
//  ViewController.m
//  DCTImageCaccheDemo
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "ViewController.h"
#import "TableViewCell.h"
#import <DCTImageCache/DCTImageCache.h>

@implementation ViewController {
	NSMutableDictionary *_processes;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	_processes = [NSMutableDictionary new];
	NSString *name = NSStringFromClass([TableViewCell class]);
	UINib *nib = [UINib nibWithNibName:name bundle:nil];
	[self.tableView registerNib:nib forCellReuseIdentifier:name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([TableViewCell class])];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(TableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

	UIImageView *imageView = cell.theImageView;
	CGFloat width = imageView.contentScaleFactor * imageView.bounds.size.width;
	CGFloat height = imageView.contentScaleFactor * imageView.bounds.size.height;

	DCTImageCacheAttributes *attributes = [DCTImageCacheAttributes new];
	attributes.key = [NSString stringWithFormat:@"%i", indexPath.row+1];
	attributes.size = CGSizeMake(width, height);

	id<DCTImageCacheProcess> process = [[DCTImageCache defaultImageCache] fetchImageWithAttributes:attributes handler:^(UIImage *image, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			imageView.alpha = 0.0f;
			imageView.image = image;
			id<DCTImageCacheProcess> process = [_processes objectForKey:@(indexPath.row)];
			[_processes removeObjectForKey:@(indexPath.row)];
			NSTimeInterval timeInterval = process ? 1.0f/3.0f : 0.0f;
			[UIView animateWithDuration:timeInterval animations:^{
				imageView.alpha = 1.0f;
			}];
		});
	}];

	if (process) [_processes setObject:process forKey:@(indexPath.row)];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(TableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	id<DCTImageCacheProcess> process = [_processes objectForKey:@(indexPath.row)];
	[process cancel];
	cell.theImageView.image = nil;
}

@end
