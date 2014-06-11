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

@interface ViewController ()
@property (nonatomic, strong) NSMutableDictionary *progresses;
@end

@implementation ViewController

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {

	TableViewCell *cell = (TableViewCell *)tableViewCell;
	UIImageView *imageView = cell.theImageView;

	DCTImageCacheAttributes *attributes = [DCTImageCacheAttributes new];
	attributes.key = [NSString stringWithFormat:@"%@", @(indexPath.row+1)];
	attributes.size = imageView.bounds.size;
	attributes.scale = tableView.window.screen.scale;

	NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
	self.progresses[indexPath] = progress;
	[progress becomeCurrentWithPendingUnitCount:1];
	[self.imageCache fetchImageWithAttributes:attributes handler:^(UIImage *image, NSError *error) {

		NSAssert(!progress.cancelled, @"The image cache should never call back if the progress is cancelled. %@", progress);

		// If the progress is still the current progress, then this method has returned instantly
		// meaning we shouldn't animate the image onscreen.
		BOOL shouldAnimate = ![progress isEqual:[NSProgress currentProgress]];

		NSTimeInterval duration = shouldAnimate ? 1.0f/3.0f : 0.0f;
		[UIView transitionWithView:imageView
						  duration:duration
						   options:UIViewAnimationOptionTransitionCrossDissolve
						animations:^{
							imageView.image = image;
						} completion:NULL];

	}];
	[progress resignCurrent];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	TableViewCell *cell = (TableViewCell *)tableViewCell;
	NSProgress *progress = self.progresses[indexPath];
	[progress cancel];
	[self.progresses removeObjectForKey:indexPath];
	[cell.theImageView.layer removeAllAnimations];
	cell.theImageView.image = nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([TableViewCell class])];
}

@end
