//
//  TableViewCell.m
//  DCTImageCache
//
//  Created by Daniel Tull on 12.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "TableViewCell.h"

@implementation TableViewCell

- (void)prepareForReuse {
	[super prepareForReuse];
	self.theImageView.image = nil;
}

@end
