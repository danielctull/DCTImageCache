// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to _DCTImageCacheItem.h instead.

@import CoreData;


extern const struct _DCTImageCacheItemAttributes {
	__unsafe_unretained NSString *date;
	__unsafe_unretained NSString *imageData;
	__unsafe_unretained NSString *key;
	__unsafe_unretained NSString *sizeString;
} _DCTImageCacheItemAttributes;

extern const struct _DCTImageCacheItemRelationships {
} _DCTImageCacheItemRelationships;

extern const struct _DCTImageCacheItemFetchedProperties {
} _DCTImageCacheItemFetchedProperties;







@interface _DCTImageCacheItemID : NSManagedObjectID {}
@end

@interface _DCTImageCacheItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (_DCTImageCacheItemID*)objectID;




@property (nonatomic, strong) NSDate* date;


//- (BOOL)validateDate:(id*)value_ error:(NSError**)error_;




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


- (NSDate*)primitiveDate;
- (void)setPrimitiveDate:(NSDate*)value;




- (NSData*)primitiveImageData;
- (void)setPrimitiveImageData:(NSData*)value;




- (NSString*)primitiveKey;
- (void)setPrimitiveKey:(NSString*)value;




- (NSString*)primitiveSizeString;
- (void)setPrimitiveSizeString:(NSString*)value;




@end
