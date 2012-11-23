// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DCTImageCacheItem.m instead.

#import "_DCTImageCacheItem.h"

const struct DCTImageCacheItemAttributes DCTImageCacheItemAttributes = {
	.imageData = @"imageData",
	.key = @"key",
	.sizeString = @"sizeString",
};

const struct DCTImageCacheItemRelationships DCTImageCacheItemRelationships = {
};

const struct DCTImageCacheItemFetchedProperties DCTImageCacheItemFetchedProperties = {
};

@implementation DCTImageCacheItemID
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

- (DCTImageCacheItemID*)objectID {
	return (DCTImageCacheItemID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic imageData;






@dynamic key;






@dynamic sizeString;











@end
