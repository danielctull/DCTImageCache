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

- (void)viewDidLoad {
    [super viewDidLoad];
	self.progresses = [NSMutableDictionary new];
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
	[[DCTImageCache defaultImageCache] fetchImageWithAttributes:attributes handler:^(UIImage *image, NSError *error) {

		NSTimeInterval duration = 0.0f;//duration ? 1.0f/3.0f : 0.0f;
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
	cell.theImageView.image = nil;
}

@end
