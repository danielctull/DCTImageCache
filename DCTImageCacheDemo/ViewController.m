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
@property (nonatomic, strong) NSMutableDictionary *processes;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.processes = [NSMutableDictionary new];
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
	CGFloat width = imageView.contentScaleFactor * imageView.bounds.size.width;
	CGFloat height = imageView.contentScaleFactor * imageView.bounds.size.height;

	DCTImageCacheAttributes *attributes = [DCTImageCacheAttributes new];
	attributes.key = [NSString stringWithFormat:@"%i", indexPath.row+1];
	attributes.size = CGSizeMake(width, height);

	id<DCTImageCacheProcess> process = [[DCTImageCache defaultImageCache] fetchImageWithAttributes:attributes handler:^(UIImage *image, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			imageView.alpha = 0.0f;
			imageView.image = image;
			id<DCTImageCacheProcess> process = [self.processes objectForKey:@(indexPath.row)];
			[self.processes removeObjectForKey:@(indexPath.row)];
			NSTimeInterval timeInterval = process ? 1.0f/3.0f : 0.0f;
			[UIView animateWithDuration:timeInterval animations:^{
				imageView.alpha = 1.0f;
			}];
		});
	}];

	if (process) [self.processes setObject:process forKey:@(indexPath.row)];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	TableViewCell *cell = (TableViewCell *)tableViewCell;
	id<DCTImageCacheProcess> process = [self.processes objectForKey:@(indexPath.row)];
	[process cancel];
	cell.theImageView.image = nil;
}

@end
