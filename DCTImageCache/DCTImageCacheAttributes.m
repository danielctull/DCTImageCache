//
//  DCTImageCacheAttributes.m
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheAttributes.h"

CGSize const DCTImageCacheAttributesNullSize = {-CGFLOAT_MAX, -CGFLOAT_MAX};

@implementation DCTImageCacheAttributes {
	NSString *_identifier;
}

- (id)init {
	self = [super init];
	if (!self) return nil;
	_size = DCTImageCacheAttributesNullSize;
	return self;
}

- (NSString *)identifier {
	if (!_identifier) _identifier = [NSString stringWithFormat:@"key:%@.size:%@.createdBefore:%@", self.key, NSStringFromCGSize(self.size), @([self.createdBefore timeIntervalSinceReferenceDate])];
	return _identifier;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; key = %@; size = %@; createdBefore = %@>", NSStringFromClass([self class]), self, self.key, NSStringFromCGSize(self.size), self.createdBefore];
}

- (NSFetchRequest *)_fetchRequest {

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[_DCTImageCacheItem entityName]];

	NSMutableArray *predicates = [[NSMutableArray alloc] initWithCapacity:3];

	if (self.key) {
		NSPredicate *keyPredicate = [NSPredicate predicateWithFormat:@"%K == %@", _DCTImageCacheItemAttributes.key, self.key];
		[predicates addObject:keyPredicate];
	}

	if (!CGSizeEqualToSize(self.size, DCTImageCacheAttributesNullSize)) {
		NSPredicate *sizePredicate = [NSPredicate predicateWithFormat:@"%K == %@", _DCTImageCacheItemAttributes.sizeString, NSStringFromCGSize(self.size)];
		[predicates addObject:sizePredicate];
	}

	if (self.createdBefore) {
		NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"%K < %@", _DCTImageCacheItemAttributes.date, self.createdBefore];
		[predicates addObject:datePredicate];
	}

	fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	return fetchRequest;
}

- (void)_setupCacheItemProperties:(_DCTImageCacheItem *)cacheItem {
	cacheItem.key = self.key;
	cacheItem.sizeString = NSStringFromCGSize(self.size);
}

@end
