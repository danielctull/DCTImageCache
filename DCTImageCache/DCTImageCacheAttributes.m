//
//  DCTImageCacheAttributes.m
//  DCTImageCache
//
//  Created by Daniel Tull on 09.12.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheAttributes.h"

NSString *const DCTImageCacheAttributesKey = @"DCTImageCacheAttributesKey";
NSString *const DCTImageCacheAttributesSize = @"DCTImageCacheAttributesSize";
NSString *const DCTImageCacheAttributesCreatedBefore = @"DCTImageCacheAttributesCreatedBefore";

CGSize const DCTImageCacheAttributesNullSize = {-CGFLOAT_MAX, -CGFLOAT_MAX};

@implementation DCTImageCacheAttributes

- (id)initWithDictionary:(NSDictionary *)dictionary {
	self = [self init];
	if (!self) return nil;
	_dictionary = [dictionary copy];
	return self;
}

- (NSString *)identifier {
	return [self.dictionary description];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; key = %@; size = %@; createdBefore = %@>",
			NSStringFromClass([self class]),
			self,
			[self _key],
			[self _sizeString],
			[self _createdBefore]];
}

- (NSFetchRequest *)_fetchRequest {

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[_DCTImageCacheItem entityName]];

	NSMutableArray *predicates = [[NSMutableArray alloc] initWithCapacity:3];

	NSString *key = [self _key];
	if (key.length > 0) {
		NSPredicate *keyPredicate = [NSPredicate predicateWithFormat:@"%K == %@", _DCTImageCacheItemAttributes.key, key];
		[predicates addObject:keyPredicate];
	}

	NSString *sizeString = [self _sizeString];
	if (sizeString.length > 0) {
		NSPredicate *sizePredicate = [NSPredicate predicateWithFormat:@"%K == %@", _DCTImageCacheItemAttributes.sizeString, sizeString];
		[predicates addObject:sizePredicate];
	}

	NSDate *createdBefore = [self _createdBefore];
	if (createdBefore) {
		NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"%K < %@", _DCTImageCacheItemAttributes.date, createdBefore];
		[predicates addObject:datePredicate];
	}

	fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	return fetchRequest;
}

- (void)_setupCacheItemProperties:(_DCTImageCacheItem *)cacheItem {
	cacheItem.key = [self _key];
	cacheItem.sizeString = [self _sizeString];
}

- (NSString *)_sizeString {
	NSValue *value = [self.dictionary objectForKey:DCTImageCacheAttributesSize];
	if (!value) return nil;
	return NSStringFromCGSize([value CGSizeValue]);
}

- (NSString *)_key {
	return [self.dictionary objectForKey:DCTImageCacheAttributesKey];
}

- (NSDate *)_createdBefore {
	return [self.dictionary objectForKey:DCTImageCacheAttributesCreatedBefore];
}

@end
