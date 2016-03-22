//
//  DCTImageCacheAttributes.m
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTImageCacheAttributes.h"

CGSize const DCTImageCacheAttributesSizeNull = {-CGFLOAT_MAX, -CGFLOAT_MAX};

@implementation DCTImageCacheAttributes

- (instancetype)init {
	self = [super init];
	if (!self) return nil;
	_size = DCTImageCacheAttributesSizeNull;
	_scale = 1.0;
	_contentMode = DCTImageCacheAttributesContentModeAspectFill;
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; %@>",
			NSStringFromClass([self class]),
			(void *)self,
			[self coreDescription]];
}

- (NSString *)coreDescription {
	return [NSString stringWithFormat:@"key = %@; size = %@; scale = %@; contentMode = %@",
			self.key,
			self.sizeString,
			@(self.scale),
			@(self.contentMode)];
}

- (NSUInteger)hash {
	return [self.coreDescription hash];
}

- (BOOL)isEqual:(id)object {

	if (![object isKindOfClass:[self class]]) {
		return NO;
	}

	DCTImageCacheAttributes *attributes = object;

	return [self.coreDescription isEqualToString:attributes.coreDescription];
}

- (instancetype)copyWithZone:(NSZone *)zone {
	DCTImageCacheAttributes *attributes = [[self class] allocWithZone:zone];
	attributes.key = self.key;
	attributes.createdBefore = self.createdBefore;
	attributes.size = self.size;
	attributes.scale = self.scale;
	attributes.contentMode = self.contentMode;
	return attributes;
}

- (NSString *)sizeString {

	if (CGSizeEqualToSize(self.size, DCTImageCacheAttributesSizeNull)) {
		return nil;
	}

	return [NSString stringWithFormat:@"(%@, %@)",
			@(self.size.width),
			@(self.size.height)];
}

@end
