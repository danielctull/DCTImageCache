// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DCTImageCacheItem.h instead.

@import CoreData;

extern const struct DCTImageCacheItemAttributes {
	__unsafe_unretained NSString *creationDate;
	__unsafe_unretained NSString *identifier;
	__unsafe_unretained NSString *key;
	__unsafe_unretained NSString *lastAccessedDate;
	__unsafe_unretained NSString *scale;
	__unsafe_unretained NSString *sizeString;
} DCTImageCacheItemAttributes;

@interface DCTImageCacheItemID : NSManagedObjectID {}
@end

@interface _DCTImageCacheItem : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (DCTImageCacheItemID*)objectID;

@property (nonatomic, strong) NSDate* creationDate;

//- (BOOL)validateCreationDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* identifier;

//- (BOOL)validateIdentifier:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* key;

//- (BOOL)validateKey:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* lastAccessedDate;

//- (BOOL)validateLastAccessedDate:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* scale;

@property (atomic) float scaleValue;
- (float)scaleValue;
- (void)setScaleValue:(float)value_;

//- (BOOL)validateScale:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* sizeString;

//- (BOOL)validateSizeString:(id*)value_ error:(NSError**)error_;

@end

@interface _DCTImageCacheItem (CoreDataGeneratedPrimitiveAccessors)

- (NSDate*)primitiveCreationDate;
- (void)setPrimitiveCreationDate:(NSDate*)value;

- (NSString*)primitiveIdentifier;
- (void)setPrimitiveIdentifier:(NSString*)value;

- (NSString*)primitiveKey;
- (void)setPrimitiveKey:(NSString*)value;

- (NSDate*)primitiveLastAccessedDate;
- (void)setPrimitiveLastAccessedDate:(NSDate*)value;

- (NSNumber*)primitiveScale;
- (void)setPrimitiveScale:(NSNumber*)value;

- (float)primitiveScaleValue;
- (void)setPrimitiveScaleValue:(float)value_;

- (NSString*)primitiveSizeString;
- (void)setPrimitiveSizeString:(NSString*)value;

@end
