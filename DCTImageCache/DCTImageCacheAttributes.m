//
//  DCTImageCacheAttributes.m
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheAttributes.h"

static CGSize const DCTImageCacheAttributesNullSize = {-CGFLOAT_MAX, -CGFLOAT_MAX};

id DCTImageCacheAttributesObjectForSize(CGSize size) {
	NSDictionary *dictionary = (__bridge NSDictionary *)CGSizeCreateDictionaryRepresentation(size);
	return dictionary;
}

@implementation DCTImageCacheAttributes

- (instancetype)init {
	self = [super init];
	if (!self) return nil;
	_size = DCTImageCacheAttributesNullSize;
	_scale = 1.0f;
	_contentMode = DCTImageCacheAttributesContentModeAspectFill;
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; %@>",
			NSStringFromClass([self class]),
			self,
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
	return [NSString stringWithFormat:@"(%@, %@)",
			@(self.size.width),
			@(self.size.height)];
}












- (NSFetchRequest *)_fetchRequest {

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[_DCTImageCacheItem entityName]];

	NSMutableArray *predicates = [[NSMutableArray alloc] initWithCapacity:3];

	NSString *key = self.key;
	if (key.length > 0) {
		NSPredicate *keyPredicate = [NSPredicate predicateWithFormat:@"%K == %@", _DCTImageCacheItemAttributes.key, key];
		[predicates addObject:keyPredicate];
	}

	NSString *sizeString = self.sizeString;
	if (sizeString.length > 0) {
		NSPredicate *sizePredicate = [NSPredicate predicateWithFormat:@"%K == %@", _DCTImageCacheItemAttributes.sizeString, sizeString];
		[predicates addObject:sizePredicate];
	}

	NSDate *createdBefore = self.createdBefore;
	if (createdBefore) {
		NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"%K < %@", _DCTImageCacheItemAttributes.date, createdBefore];
		[predicates addObject:datePredicate];
	}

	fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	return fetchRequest;
}

@end
