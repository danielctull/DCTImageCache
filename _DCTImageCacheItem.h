// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DCTImageCacheItem.h instead.

#import <CoreData/CoreData.h>


extern const struct DCTImageCacheItemAttributes {
	__unsafe_unretained NSString *imageData;
	__unsafe_unretained NSString *key;
	__unsafe_unretained NSString *sizeString;
} DCTImageCacheItemAttributes;

extern const struct DCTImageCacheItemRelationships {
} DCTImageCacheItemRelationships;

extern const struct DCTImageCacheItemFetchedProperties {
} DCTImageCacheItemFetchedProperties;






@interface DCTImageCacheItemID : NSManagedObjectID {}
@end

@interface _DCTImageCacheItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (DCTImageCacheItemID*)objectID;




@property (nonatomic, strong) NSData* imageData;


//- (BOOL)validateImageData:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* key;


//- (BOOL)validateKey:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* sizeString;


//- (BOOL)validateSizeString:(id*)value_ error:(NSError**)error_;






@end

@interface _DCTImageCacheItem (CoreDataGeneratedAccessors)

@end

@interface _DCTImageCacheItem (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitiveImageData;
- (void)setPrimitiveImageData:(NSData*)value;




- (NSString*)primitiveKey;
- (void)setPrimitiveKey:(NSString*)value;




- (NSString*)primitiveSizeString;
- (void)setPrimitiveSizeString:(NSString*)value;




@end
