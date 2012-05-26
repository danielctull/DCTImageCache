//
//  DCTImageCache.m
//  Tweetville
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "DCTImageCache.h"
#import "UIImage+DCTCropping.h"

@interface DCTInternalMemoryImageCache : NSObject
- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size;
- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size;
- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size;
@end

@interface DCTInternalDiskImageCache : NSObject
- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size;
- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size;
- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size;
@end

@interface DCTInternalImageCacheHashStore : NSObject
- (id)initWithPath:(NSString *)path;
- (NSString *)hashForKey:(NSString *)key;
- (NSString *)keyForHash:(NSString *)hash;
- (void)removeHashForKey:(NSString *)key;
- (BOOL)containsHashForKey:(NSString *)key;
@end

@implementation DCTImageCache {
	__strong NSString *_path;
	__strong DCTInternalMemoryImageCache *_memoryCache;
	__strong DCTInternalImageCacheHashStore *_hashStore;
}
@synthesize name = _name;
@synthesize imageDownloader = _imageDownloader;

+ (void)load {
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		NSDate *now = [NSDate date];
		
		[self enumerateImageCachesUsingBlock:^(DCTImageCache *imageCache, BOOL *stop) {
			
			
			[imageCache enumerateKeysUsingBlock:^(NSString *key, BOOL *stop) {
				
				NSDictionary *attributes = [imageCache attributesForImageWithKey:key];
				
				if (!attributes) {
					[imageCache deleteImagesForKey:key];
					return;
				}
				
				NSDate *creationDate = [attributes objectForKey:NSFileCreationDate];
				NSTimeInterval timeInterval = [now timeIntervalSinceDate:creationDate];
				
				if (timeInterval > 604800) // 7 days
					[imageCache deleteImagesForKey:key];
			}];
		}];
	});
}

+ (DCTImageCache *)defaultImageCache {
	static DCTImageCache *sharedInstance = nil;
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString *defaultPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:NSStringFromClass(self)];
		defaultPath = [defaultPath stringByAppendingPathComponent:@"DefaultCache"];
		sharedInstance = [[self alloc] initWithPath:defaultPath];
	});
	return sharedInstance;
}

- (id)initWithName:(NSString *)name {
	if (!(self = [super init])) return nil;
	_name = [name copy];
	_path = [[[self class] defaultCachePath] stringByAppendingPathComponent:name];
	_hashStore = [[DCTInternalImageCacheHashStore alloc] initWithPath:[self hashesPath]];	
	return self;
}

- (BOOL)hasImageForKey:(NSString *)key {
	return [_hashStore containsHashForKey:key];
}

- (UIImage *)imageForKey:(NSString *)key {
	return [self imageForKey:key size:CGSizeZero];
}

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size {
	
	UIImage *image = [_memoryCache imageForKey:key size:size];
	
	if (!image) {
		NSString *imagePath = [self imagePathForKey:key size:size];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSData *data = [fileManager contentsAtPath:imagePath];
		image = [UIImage imageWithData:data];
	}
	
	if (!image && !CGSizeEqualToSize(size, CGSizeZero)) {
		UIImage *originalImage = [self imageForKey:key];
		image = [self imageFromOriginalImage:originalImage key:key size:size];
	}
	
	return image;
}

- (void)fetchImageForKey:(NSString *)key imageBlock:(void (^)(UIImage *))block {
	[self fetchImageForKey:key size:CGSizeZero imageBlock:block];
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size imageBlock:(void (^)(UIImage *))block {
	
	UIImage *image = [self imageForKey:key size:size];
	
	if (image) {
		if (block != NULL) block(image);
		return;
	}
	
	if (self.imageDownloader == NULL) return;
	
	self.imageDownloader(key, ^(UIImage *image){
		[self storeImage:image forKey:key size:CGSizeZero];		
		image = [self imageFromOriginalImage:image key:key size:size];
		if (block != NULL) block(image);
	});
}

#pragma mark - Internal

- (NSString *)hashesPath {
	return [_path stringByAppendingPathComponent:@".hashes"];
}

- (NSString *)directoryForKey:(NSString *)key {
	NSString *hash = [_hashStore hashForKey:key];
	return [_path stringByAppendingPathComponent:hash];
}

- (NSString *)imagePathForKey:(NSString *)key size:(CGSize)size {
	NSString *sizeString = sizeString = NSStringFromCGSize(size);	
	NSString *path = [self directoryForKey:key];
	path = [path stringByAppendingPathComponent:sizeString];
	return path;
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	
	[_memoryCache setImage:image forKey:key size:size];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *directoryPath = [self directoryForKey:key];
	NSString *imagePath = [directoryPath stringByAppendingPathComponent:NSStringFromCGSize(size)];
	
	if (![fileManager fileExistsAtPath:directoryPath])
		[fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
	
	[fileManager createFileAtPath:imagePath contents:UIImagePNGRepresentation(image) attributes:nil];
}

- (UIImage *)imageFromOriginalImage:(UIImage *)image key:(NSString *)key size:(CGSize)size {
	
	if (!image) return nil;
	
	if (!CGSizeEqualToSize(size, CGSizeZero)) {
		image = [image dct_imageToFitSize:size];
		[self storeImage:image forKey:key size:size];
	}
	
	return image;
	
}

+ (NSString *)defaultCachePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex:0] stringByAppendingPathComponent:NSStringFromClass(self)];
}

+ (void)enumerateImageCachesUsingBlock:(void (^)(DCTImageCache *imageCache, BOOL *stop))block {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *cachePath = [[self class] defaultCachePath];
	NSArray *caches = [[fileManager contentsOfDirectoryAtPath:cachePath error:nil] copy];
	
	[caches enumerateObjectsUsingBlock:^(NSString *name, NSUInteger i, BOOL *stop) {
		DCTImageCache *imageCache = [[DCTImageCache alloc] initWithName:name];
		block(imageCache, stop);
	}];
}

- (void)enumerateKeysUsingBlock:(void (^)(NSString *key, BOOL *stop))block {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *filenames = [[fileManager contentsOfDirectoryAtPath:_path error:nil] copy];
	
	[filenames enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger i, BOOL *stop) {
		NSString *key = [_hashStore keyForHash:filename];
		block(key, stop);
	}];
}

- (NSDictionary *)attributesForImageWithKey:(NSString *)key {
	NSString *path = [self imagePathForKey:key size:CGSizeZero];
	return [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
}
- (void)deleteImagesForKey:(NSString *)key {
	[_hashStore removeHashForKey:key];
	NSString *directoryPath = [self directoryForKey:key];
	[[NSFileManager defaultManager] removeItemAtPath:directoryPath error:nil];
}

@end





@implementation DCTInternalImageCacheHashStore {
	__strong NSMutableDictionary *_hashes;
	__strong NSString *_path;
}

- (id)initWithPath:(NSString *)path {
	if (!(self = [super init])) return nil;
	_path = [path copy];
	_hashes=  [NSMutableDictionary dictionaryWithContentsOfFile:_path];
	if (!_hashes) _hashes = [NSMutableDictionary new];	
	return self;
}

- (void)storeKey:(NSString *)key forHash:(NSString *)hash {
	
	if ([key length] == 0) return;
	if ([[_hashes allKeys] containsObject:hash]) return;
	
	[_hashes setObject:key forKey:hash];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[_hashes writeToFile:_path atomically:YES];
	});
}

- (BOOL)containsHashForKey:(NSString *)key {
	return [[_hashes allValues] containsObject:key];
}

- (NSString *)keyForHash:(NSString *)hash {
	return [_hashes objectForKey:hash];
}

- (NSString *)hashForKey:(NSString *)key {	
	NSString *hash = [NSString stringWithFormat:@"%u", [key hash]];
	[self storeKey:key forHash:hash];
	return hash;
}

- (void)removeHashForKey:(NSString *)key {
	
	if ([key length] == 0) return;
	
	NSString *hash = [NSString stringWithFormat:@"%u", [key hash]];
	[_hashes removeObjectForKey:hash];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[_hashes writeToFile:_path atomically:YES];
	});
}

@end






@implementation DCTInternalMemoryImageCache {
	__strong NSMutableDictionary *_cache;
}

- (id)init {
	if (!(self = [super init])) return nil;
	_cache = [NSMutableDictionary new];
	return self;
}

- (NSMutableDictionary *)imageCacheForKey:(NSString *)key {
	NSMutableDictionary *dictionary = [_cache objectForKey:key];
	if (!dictionary) dictionary = [NSMutableDictionary new];
	return dictionary;
}

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size {
	NSDictionary *dictionary = [self imageCacheForKey:key];
	return [[dictionary allKeys] containsObject:NSStringFromCGSize(size)];
}

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size {
	NSDictionary *dictionary = [self imageCacheForKey:key];
	return [dictionary objectForKey:NSStringFromCGSize(size)];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	NSMutableDictionary *dictionary = [self imageCacheForKey:key];
	[dictionary setObject:image forKey:NSStringFromCGSize(size)];
}

@end






@implementation DCTInternalDiskImageCache

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size {
	
}

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size {
	
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	
}

@end









































