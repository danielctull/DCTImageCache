//
//  DCTImageCache.m
//  Tweetville
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "DCTImageCache.h"

@interface DCTInternalMemoryImageCache : NSObject
- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size;
- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size;
- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size;
@end

@interface DCTInternalDiskImageCache : NSObject
- (id)initWithPath:(NSString *)path;
- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void (^)(UIImage *))handler;
- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size;
- (void)fetchAttributesForImageWithKey:(NSString *)key size:(CGSize)size handler:(void (^)(NSDictionary *))handler;
- (void)removeImagesForKey:(NSString *)key;
- (void)enumerateKeysUsingBlock:(void (^)(NSString *key, BOOL *stop))block;
@end

@implementation DCTImageCache {
	__strong DCTInternalDiskImageCache *_diskCache;
	__strong DCTInternalMemoryImageCache *_memoryCache;
}
@synthesize name = _name;
@synthesize imageFetcher = _imageFetcher;

#pragma mark - NSObject

+ (void)load {
	
	NSDate *now = [NSDate date];
	
	[self enumerateImageCachesUsingBlock:^(DCTImageCache *imageCache, BOOL *stop) {
		
		DCTInternalDiskImageCache *diskCache = imageCache->_diskCache;
		[diskCache enumerateKeysUsingBlock:^(NSString *key, BOOL *stop) {
		
			[diskCache fetchAttributesForImageWithKey:key size:CGSizeZero handler:^(NSDictionary *attributes) {
			
				if (!attributes) {
					[diskCache removeImagesForKey:key];
					return;
				}
					
				NSDate *creationDate = [attributes objectForKey:NSFileCreationDate];
				NSTimeInterval timeInterval = [now timeIntervalSinceDate:creationDate];
				
				if (timeInterval > 604800) // 7 days
					[diskCache removeImagesForKey:key];
			}];
		}];
	}];
}

#pragma mark - DCTImageCache

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
	_memoryCache = [DCTInternalMemoryImageCache new];
	NSString *path = [[[self class] defaultCachePath] stringByAppendingPathComponent:name];
	_diskCache = [[DCTInternalDiskImageCache alloc] initWithPath:path];
	return self;
}

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size {
	return [_memoryCache hasImageForKey:key size:size];
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void (^)(UIImage *))theHandler {
	
	void (^handler)(UIImage *) = [theHandler copy];
	
	UIImage *image = [_memoryCache imageForKey:key size:size];
	if (image) {
		[self sendImage:image toHandler:handler];
		return;
	}
	
	[_diskCache fetchImageForKey:key size:size handler:^(UIImage *image) {
		
		if (image) {
			[_memoryCache setImage:image forKey:key size:size];
			[self sendImage:image toHandler:handler];
			return;
		}
		
		if (self.imageFetcher == NULL) return;
		
		self.imageFetcher(key, size, ^(UIImage *image) {
			
			if (!image) return;
			
			[_memoryCache setImage:image forKey:key size:size];
			[_diskCache setImage:image forKey:key size:size];
			[self sendImage:image toHandler:handler];
		});
	}];
}

#pragma mark - Internal

- (void)sendImage:(UIImage *)image toHandler:(void (^)(UIImage *))handler {
	if (handler == NULL) return;
	handler(image);	
}

+ (NSString *)defaultCachePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex:0] stringByAppendingPathComponent:NSStringFromClass(self)];
}

+ (void)enumerateImageCachesUsingBlock:(void (^)(DCTImageCache *imageCache, BOOL *stop))block {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
	
		NSFileManager *fileManager = [NSFileManager new];
		NSString *cachePath = [[self class] defaultCachePath];
		NSArray *caches = [[fileManager contentsOfDirectoryAtPath:cachePath error:nil] copy];
	
		[caches enumerateObjectsUsingBlock:^(NSString *name, NSUInteger i, BOOL *stop) {
			DCTImageCache *imageCache = [[DCTImageCache alloc] initWithName:name];
			block(imageCache, stop);
		}];
	});
}

@end



@interface DCTInternalImageCacheHashStore : NSObject
- (id)initWithPath:(NSString *)path;
- (NSString *)hashForKey:(NSString *)key;
- (NSString *)keyForHash:(NSString *)hash;
- (void)removeHashForKey:(NSString *)key;
- (BOOL)containsHashForKey:(NSString *)key;
@end

@implementation DCTInternalImageCacheHashStore {
	__strong NSMutableDictionary *_hashes;
	__strong NSString *_path;
}

+ (dispatch_queue_t)queue {
	static dispatch_queue_t sharedQueue = nil;
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		sharedQueue = dispatch_queue_create("uk.co.danieltull.DCTInternalImageCacheHashStore", NULL);
	});
	return sharedQueue;
}
- (dispatch_queue_t)queue {
	return [[self class] queue];
}

- (id)initWithPath:(NSString *)path {
	if (!(self = [super init])) return nil;
	_path = [path copy];
	dispatch_sync(self.queue, ^{
		_hashes=  [NSMutableDictionary dictionaryWithContentsOfFile:_path];
		if (!_hashes) _hashes = [NSMutableDictionary new];
	});
	return self;
}

- (void)storeKey:(NSString *)key forHash:(NSString *)hash {
	dispatch_async(self.queue, ^{
		if ([key length] == 0) return;
		if ([[_hashes allKeys] containsObject:hash]) return;
		
		[_hashes setObject:key forKey:hash];
		[_hashes writeToFile:_path atomically:YES];
	});
}

- (BOOL)containsHashForKey:(NSString *)key {
	__block BOOL contains = NO;
	dispatch_sync(self.queue, ^{
		contains = [[_hashes allValues] containsObject:key];
	});
	return contains;
}

- (NSString *)keyForHash:(NSString *)hash {
	__block NSString *key = nil;
	dispatch_sync(self.queue, ^{
		key = [_hashes objectForKey:hash];
	});
	return key;
}

- (NSString *)hashForKey:(NSString *)key {
	NSString *hash = [NSString stringWithFormat:@"%u", [key hash]];
	[self storeKey:key forHash:hash];
	return hash;
}

- (void)removeHashForKey:(NSString *)key {
	dispatch_async(self.queue, ^{
		if ([key length] == 0) return;
	
		NSString *hash = [NSString stringWithFormat:@"%u", [key hash]];
		[_hashes removeObjectForKey:hash];
		[_hashes writeToFile:_path atomically:YES];
	});
}

@end






@implementation DCTInternalMemoryImageCache {
	__strong NSMutableDictionary *_cache;
	__strong NSMutableDictionary *_cacheAccessCount;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIApplicationDidReceiveMemoryWarningNotification
												  object:nil];
}

- (id)init {
	if (!(self = [super init])) return nil;
	_cache = [NSMutableDictionary new];
	_cacheAccessCount = [NSMutableDictionary new];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(didReceiveMemoryWarning:)
												 name:UIApplicationDidReceiveMemoryWarningNotification
											   object:nil];
	
	return self;
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
		
	dispatch_async(dispatch_get_main_queue(), ^{
		
		NSArray *counts = [[_cacheAccessCount allValues] sortedArrayUsingSelector:@selector(compare:)];
		NSNumber *mediumCountNumber = [counts objectAtIndex:[counts count]/2];
		NSInteger mediumCount = [mediumCountNumber integerValue];
		
		[_cacheAccessCount enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSNumber *count, BOOL *stop) {
			
			if ([count integerValue] > mediumCount) return;
			
			NSArray *array = [accessKey componentsSeparatedByString:@"+"];
			NSString *key = [array objectAtIndex:0];
			NSString *sizeString = [array objectAtIndex:1];
			NSMutableDictionary *dictionary = [self imageCacheForKey:key];
			[dictionary removeObjectForKey:sizeString];
			if ([dictionary count] == 0) [_cache removeObjectForKey:key];
		}];
	});
}

- (void)didAskForImageWithKey:(NSString *)key size:(CGSize)size {
	NSString *accessKey = [NSString stringWithFormat:@"%@+%@", key, NSStringFromCGSize(size)];
	NSNumber *count = [_cacheAccessCount objectForKey:accessKey];
	[_cacheAccessCount setObject:[NSNumber numberWithInteger:[count integerValue]+1] forKey:accessKey];
}

- (NSMutableDictionary *)imageCacheForKey:(NSString *)key {
	NSMutableDictionary *dictionary = [_cache objectForKey:key];
	if (!dictionary) {
		dictionary = [NSMutableDictionary new];
		[_cache setObject:dictionary forKey:key];
	}
	return dictionary;
}

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size {
	NSDictionary *dictionary = [self imageCacheForKey:key];
	return [[dictionary allKeys] containsObject:NSStringFromCGSize(size)];
}

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size {
	[self didAskForImageWithKey:key size:size];
	NSDictionary *dictionary = [self imageCacheForKey:key];
	return [dictionary objectForKey:NSStringFromCGSize(size)];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	NSMutableDictionary *dictionary = [self imageCacheForKey:key];
	[dictionary setObject:image forKey:NSStringFromCGSize(size)];
}

@end




@implementation DCTInternalDiskImageCache {
	__strong NSString *_path;
	__strong DCTInternalImageCacheHashStore *_hashStore;
	__strong NSFileManager *_fileManager;
}

+ (dispatch_queue_t)queue {
	static dispatch_queue_t sharedQueue = nil;
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		sharedQueue = dispatch_queue_create("uk.co.danieltull.DCTInternalDiskImageCache", NULL);
	});
	return sharedQueue;
}
- (dispatch_queue_t)queue {
	return [[self class] queue];
}

- (id)initWithPath:(NSString *)path {
	if (!(self = [super init])) return nil;
	_path = [path copy];
	dispatch_sync([self queue], ^{
		_hashStore = [[DCTInternalImageCacheHashStore alloc] initWithPath:[self hashesPath]];
		_fileManager = [NSFileManager new];
	});
	return self;
}

- (void)removeImagesForKey:(NSString *)key {
	dispatch_async(self.queue, ^{
		[_hashStore removeHashForKey:key];
		NSString *directoryPath = [self pathForKey:key];
		[_fileManager removeItemAtPath:directoryPath error:nil];
	});
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void (^)(UIImage *))handler {
	dispatch_queue_t callingQueue = dispatch_get_current_queue();
	dispatch_async(self.queue, ^{
		NSString *imagePath = [self pathForKey:key size:size];
		NSData *data = [_fileManager contentsAtPath:imagePath];
		UIImage *image = [UIImage imageWithData:data];
		dispatch_async(callingQueue, ^{
			handler(image);
		});
	});
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	dispatch_async(self.queue, ^{
		NSString *path = [self pathForKey:key];
		NSString *imagePath = [self pathForKey:key size:size];
	
		if (![_fileManager fileExistsAtPath:path])
			[_fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
	
		[_fileManager createFileAtPath:imagePath contents:UIImagePNGRepresentation(image) attributes:nil];
	});
}

- (void)fetchAttributesForImageWithKey:(NSString *)key size:(CGSize)size handler:(void (^)(NSDictionary *))handler {
	dispatch_queue_t callingQueue = dispatch_get_current_queue();
	dispatch_async(self.queue, ^{
		NSString *path = [self pathForKey:key size:size];
		NSDictionary *dictionary = [_fileManager attributesOfItemAtPath:path error:nil];
		dispatch_async(callingQueue, ^{
			handler(dictionary);
		});
	});
}

- (void)enumerateKeysUsingBlock:(void (^)(NSString *key, BOOL *stop))block {
	dispatch_queue_t callingQueue = dispatch_get_current_queue();
	dispatch_async(self.queue, ^{
		NSArray *filenames = [[_fileManager contentsOfDirectoryAtPath:_path error:nil] copy];
		
		[filenames enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger i, BOOL *stop) {
			NSString *key = [_hashStore keyForHash:filename];
			dispatch_async(callingQueue, ^{
				block(key, stop);
			});
		}];
	});
}

#pragma mark - Internal

- (NSString *)pathForKey:(NSString *)key size:(CGSize)size {
	NSString *path = [self pathForKey:key];
	return [path stringByAppendingPathComponent:NSStringFromCGSize(size)];
}

- (NSString *)pathForKey:(NSString *)key {
	NSString *hash = [_hashStore hashForKey:key];
	return [_path stringByAppendingPathComponent:hash];
}

- (NSString *)hashesPath {
	return [_path stringByAppendingPathComponent:@".hashes"];
}

@end
