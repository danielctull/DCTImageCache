// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DCTImageCacheItem.m instead.

#import "_DCTImageCacheItem.h"

const struct DCTImageCacheItemAttributes DCTImageCacheItemAttributes = {
	.creationDate = @"creationDate",
	.imageData = @"imageData",
	.key = @"key",
	.lastAccessedDate = @"lastAccessedDate",
	.scale = @"scale",
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

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"scaleValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"scale"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic creationDate;






@dynamic imageData;






@dynamic key;






@dynamic lastAccessedDate;






@dynamic scale;



- (float)scaleValue {
	NSNumber *result = [self scale];
	return [result floatValue];
}

- (void)setScaleValue:(float)value_ {
	[self setScale:[NSNumber numberWithFloat:value_]];
}

- (float)primitiveScaleValue {
	NSNumber *result = [self primitiveScale];
	return [result floatValue];
}

- (void)setPrimitiveScaleValue:(float)value_ {
	[self setPrimitiveScale:[NSNumber numberWithFloat:value_]];
}





@dynamic sizeString;











@end
