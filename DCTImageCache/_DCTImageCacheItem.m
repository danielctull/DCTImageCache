// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to _DCTImageCacheItem.m instead.

#import "_DCTImageCacheItem.h"

const struct _DCTImageCacheItemAttributes _DCTImageCacheItemAttributes = {
	.date = @"date",
	.imageData = @"imageData",
	.key = @"key",
	.sizeString = @"sizeString",
};

const struct _DCTImageCacheItemRelationships _DCTImageCacheItemRelationships = {
};

const struct _DCTImageCacheItemFetchedProperties _DCTImageCacheItemFetchedProperties = {
};

@implementation _DCTImageCacheItemID
@end

@implementation _DCTImageCacheItem

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"DCTImageCacheItem" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"DCTImageCacheItem";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"DCTImageCacheItem" inManagedObjectContext:moc_];
}

- (_DCTImageCacheItemID*)objectID {
	return (_DCTImageCacheItemID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic date;






@dynamic imageData;






@dynamic key;






@dynamic sizeString;











@end
