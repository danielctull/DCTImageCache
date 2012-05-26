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
- (id)initWithPath:(NSString *)path;
- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size;
- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size;
- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size;
- (NSDictionary *)attributesForImageWithKey:(NSString *)key size:(CGSize)size;
- (void)removeImagesForKey:(NSString *)key;
- (void)enumerateKeysUsingBlock:(void (^)(NSString *key, BOOL *stop))block;
@end

@implementation DCTImageCache {
	__strong DCTInternalDiskImageCache *_diskCache;
	__strong DCTInternalMemoryImageCache *_memoryCache;
	dispatch_queue_t _queue;
}
@synthesize name = _name;
@synthesize imageFetcher = _imageFetcher;

#pragma mark - NSObject

+ (void)load {
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		NSDate *now = [NSDate date];
		
		[self enumerateImageCachesUsingBlock:^(DCTImageCache *imageCache, BOOL *stop) {
			
			DCTInternalDiskImageCache *diskCache = imageCache->_diskCache;
			[diskCache enumerateKeysUsingBlock:^(NSString *key, BOOL *stop) {
				
				NSDictionary *attributes = [diskCache attributesForImageWithKey:key size:CGSizeZero];
				
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
	});
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
	_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
	NSString *path = [[[self class] defaultCachePath] stringByAppendingPathComponent:name];
	_diskCache = [[DCTInternalDiskImageCache alloc] initWithPath:path];
	return self;
}

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size {
	return [_memoryCache hasImageForKey:key size:size];
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void (^)(UIImage *))handler {
	
	UIImage *image = [_memoryCache imageForKey:key size:size];
	if (image) {
		if (handler != NULL) handler(image);
		return;
	}
	
	dispatch_queue_t callingQueue = dispatch_get_current_queue();
	
	dispatch_async(_queue, ^{
		
		UIImage *image = [_diskCache imageForKey:key size:size];
		if (image) {
			if (handler != NULL)
				dispatch_async(callingQueue, ^{
					[_memoryCache setImage:image forKey:key size:size];
					handler(image);
				});
			return;
		}
	
		if (self.imageFetcher == NULL) return;
		
		dispatch_async(callingQueue, ^{
		
			self.imageFetcher(key, size, ^(UIImage *image) {
				
				if (!image) return;
				
				dispatch_async(_queue, ^{
					
					[_diskCache setImage:image forKey:key size:CGSizeZero];
					UIImage *resizedImage = [image dct_imageToFitSize:size];
					
					dispatch_async(callingQueue, ^{
						[_memoryCache setImage:resizedImage forKey:key size:size];
					});
					
					[_diskCache setImage:resizedImage forKey:key size:size];
					if (handler != NULL) dispatch_async(callingQueue, ^{handler(resizedImage);});
				});
			});
		});
	});
}

#pragma mark - Internal

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
	[_hashes writeToFile:_path atomically:YES];
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
	[_hashes writeToFile:_path atomically:YES];
}

@end






@implementation DCTInternalMemoryImageCache {
	__strong NSMutableDictionary *_cache;
	__strong NSMutableArray *_cacheAccess;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIApplicationDidReceiveMemoryWarningNotification
												  object:[UIApplication sharedApplication]];
}

- (id)init {
	if (!(self = [super init])) return nil;
	_cache = [NSMutableDictionary new];
	_cacheAccess = [NSMutableArray new];
	
	NSLog(@"%@:%@", self, NSStringFromSelector(_cmd));
	
	[NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(didReceiveMemoryWarning:) userInfo:nil repeats:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(didReceiveMemoryWarning:)
												 name:UIApplicationDidReceiveMemoryWarningNotification
											   object:[UIApplication sharedApplication]];
	
	return self;
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
	
	NSLog(@"%@:%@", self, NSStringFromSelector(_cmd));
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		NSLog(@"%@:%@ %i %@", self, NSStringFromSelector(_cmd), [_cacheAccess count], _cacheAccess);
		
		NSRange rangeToRemove = NSMakeRange(0, [_cacheAccess count]/2);
		NSArray *toRemove = [_cacheAccess subarrayWithRange:rangeToRemove];
		[_cacheAccess removeObjectsInRange:rangeToRemove];
		
		[toRemove enumerateObjectsUsingBlock:^(NSString *accessKey, NSUInteger i, BOOL *stop) {
			NSArray *array = [accessKey componentsSeparatedByString:@"+"];
			NSString *key = [array objectAtIndex:0];
			NSString *sizeString = [array objectAtIndex:1];
			NSMutableDictionary *dictionary = [self imageCacheForKey:key];
			[dictionary removeObjectForKey:sizeString];
			if ([dictionary count] == 0) [_cache removeObjectForKey:key];
		}];
		
		NSLog(@"%@:%@ %i %@", self, NSStringFromSelector(_cmd), [_cacheAccess count], _cacheAccess);
		NSLog(@"%@", _cache);
		
	});
}

- (void)didAskForImageWithKey:(NSString *)key size:(CGSize)size {
	
	NSString *accessKey = [NSString stringWithFormat:@"%@+%@", key, NSStringFromCGSize(size)];
	
	if ([_cacheAccess containsObject:accessKey])
		[_cacheAccess removeObject:accessKey];
	
	[_cacheAccess addObject:accessKey];
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

- (id)initWithPath:(NSString *)path {
	if (!(self = [super init])) return nil;
	_path = [path copy];
	_hashStore = [[DCTInternalImageCacheHashStore alloc] initWithPath:[self hashesPath]];
	_fileManager = [NSFileManager defaultManager];
	return self;
}

- (void)removeImagesForKey:(NSString *)key {
	[_hashStore removeHashForKey:key];
	NSString *directoryPath = [self pathForKey:key];
	[_fileManager removeItemAtPath:directoryPath error:nil];
}

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size {
	NSString *imagePath = [self pathForKey:key size:size];
	return [_fileManager fileExistsAtPath:imagePath];
}

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size {
	NSString *imagePath = [self pathForKey:key size:size];
	NSData *data = [_fileManager contentsAtPath:imagePath];
	return [UIImage imageWithData:data];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	
	NSString *path = [self pathForKey:key];
	NSString *imagePath = [self pathForKey:key size:size];
	
	if (![_fileManager fileExistsAtPath:path])
		[_fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
	
	[_fileManager createFileAtPath:imagePath contents:UIImagePNGRepresentation(image) attributes:nil];
}

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

- (NSDictionary *)attributesForImageWithKey:(NSString *)key size:(CGSize)size {
	NSString *path = [self pathForKey:key size:size];
	return [_fileManager attributesOfItemAtPath:path error:nil];
}

- (void)enumerateKeysUsingBlock:(void (^)(NSString *key, BOOL *stop))block {
	
	NSArray *filenames = [[_fileManager contentsOfDirectoryAtPath:_path error:nil] copy];
	
	[filenames enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger i, BOOL *stop) {
		NSString *key = [_hashStore keyForHash:filename];
		block(key, stop);
	}];
}

@end
