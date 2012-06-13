//
//  DCTImageCache.m
//  Tweetville
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "DCTImageCache.h"

@interface DCTInternalDiskImageCache : NSObject
- (id)initWithPath:(NSString *)path;
- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void (^)(UIImage *))handler;
- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size;
- (void)fetchAttributesForImageWithKey:(NSString *)key size:(CGSize)size handler:(void (^)(NSDictionary *))handler;

- (void)removeAllImages;
- (void)removeImagesForKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key size:(CGSize)size;

- (void)enumerateKeysUsingBlock:(void (^)(NSString *key, BOOL *stop))block;
- (void)enumerateSizesForKey:(NSString *)key usingBlock:(void (^)(CGSize size, BOOL *stop))block;
@end


@interface UIImage (DCTImageCache)
- (void)dctImageCache_decompress;
@end

#pragma mark -

@implementation DCTImageCache {
	__strong DCTInternalDiskImageCache *_diskCache;
	__strong NSCache *_memoryCache;
	__strong NSMutableDictionary *_imageHandlers;
	dispatch_queue_t _queue;
}
@synthesize name = _name;
@synthesize imageFetcher = _imageFetcher;

#pragma mark NSObject

+ (void)load {
	
	NSDate *now = [NSDate date];
	
	[self _enumerateImageCachesUsingBlock:^(DCTImageCache *imageCache, BOOL *stop) {
		
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

#pragma mark DCTImageCache

+ (NSMutableDictionary *)imageCaches {
	static NSMutableDictionary *sharedInstance = nil;
	static dispatch_once_t sharedToken;
	dispatch_once(&sharedToken, ^{
		sharedInstance = [NSMutableDictionary new];
	});
	return sharedInstance;
}

+ (DCTImageCache *)defaultImageCache {
	return [self imageCacheWithName:@"DCTDefaultImageCache"];
}

+ (DCTImageCache *)imageCacheWithName:(NSString *)name {
	
	NSMutableDictionary *imageCaches = [self imageCaches];
	DCTImageCache *imageCache = [imageCaches objectForKey:name];
	if (!imageCache) {
		imageCache = [[self alloc] _initWithName:name];
		[imageCaches setObject:imageCache forKey:name];
	}
	return imageCache;
}

- (void)dealloc {
	dispatch_release(_queue);
}

- (id)_initWithName:(NSString *)name {
	if (!(self = [super init])) return nil;
	NSString *queueName = [NSString stringWithFormat:@"uk.co.danieltull.DCTImageCache.%@", name];
	_queue = dispatch_queue_create([queueName cStringUsingEncoding:NSUTF8StringEncoding], NULL);
	dispatch_sync(_queue, ^{
		_name = [name copy];
		_memoryCache = [NSCache new];
		_imageHandlers = [NSMutableDictionary new];
		NSString *path = [[[self class] _defaultCachePath] stringByAppendingPathComponent:name];
		_diskCache = [[DCTInternalDiskImageCache alloc] initWithPath:path];
	});
	return self;
}
- (void)removeAllImages {
	[_memoryCache removeAllObjects];
	[_diskCache removeAllImages];
}
- (void)removeAllImagesForKey:(NSString *)key {
	[_diskCache enumerateSizesForKey:key usingBlock:^(CGSize size, BOOL *stop) {
		[_memoryCache removeObjectForKey:[self _cacheNameForKey:key size:size]];
	}];
	[_diskCache removeImagesForKey:key];
}
- (void)removeImageForKey:(NSString *)key size:(CGSize)size {
	[_memoryCache removeObjectForKey:[self _cacheNameForKey:key size:size]];
	[_diskCache removeImageForKey:key size:size];
}

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size; {
	NSString *cacheKey = [self _cacheNameForKey:key size:size];
	return [_memoryCache objectForKey:cacheKey];
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void (^)(UIImage *))theHandler {
	
	NSString *cacheKey = [self _cacheNameForKey:key size:size];
	UIImage *image = [_memoryCache objectForKey:cacheKey];
	if (image) {
		if (theHandler != NULL) theHandler(image);
		return;
	}
	
	dispatch_async(_queue, ^{
		
		void (^handler)(UIImage *) = ^(UIImage *image) {
			if (theHandler != NULL) theHandler(image);
		};
		
		NSMutableArray *handlers = [self _imageHandlersForKey:key size:size];
		[handlers addObject:handler];
		
		if ([handlers count] > 1) return;
		
		__block BOOL saveToDisk = NO;
		void (^imageHandler)(UIImage *image) = ^(UIImage *image) {
			dispatch_async(_queue, ^{
				if (!image) return;
				[image dctImageCache_decompress];
				[_memoryCache setObject:image forKey:cacheKey];
				if (saveToDisk) [_diskCache setImage:image forKey:key size:size];
				[self _sendImage:image toHandlersForKey:key size:size];
			});
		};
		
		[_diskCache fetchImageForKey:key size:size handler:^(UIImage *image) {
			
			if (image) {
				imageHandler(image);
				return;
			}
			
			if (self.imageFetcher == NULL) return;
			
			saveToDisk = YES;
			self.imageFetcher(key, size, imageHandler);
		}];
	});
}

#pragma mark Internal

- (NSString *)_cacheNameForKey:(NSString *)key size:(CGSize)size {
	return [NSString stringWithFormat:@"%@.%@", key, NSStringFromCGSize(size)];
}

- (NSMutableArray *)_imageHandlersForKey:(NSString *)key size:(CGSize)size {
	NSString *accessKey = [NSString stringWithFormat:@"%@+%@", key, NSStringFromCGSize(size)];
	NSMutableArray *handlers = [_imageHandlers objectForKey:accessKey];
	if (!handlers) {
		handlers = [NSMutableArray new];
		[_imageHandlers setObject:handlers forKey:accessKey];
	}
	return handlers;
}

- (void)_sendImage:(UIImage *)image toHandlersForKey:(NSString *)key size:(CGSize)size {
	NSMutableArray *handlers = [self _imageHandlersForKey:key size:size];
	[handlers enumerateObjectsUsingBlock:^(void(^handler)(UIImage *), NSUInteger idx, BOOL *stop) {
		handler(image);
	}];
	[handlers removeAllObjects];
}

+ (NSString *)_defaultCachePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex:0] stringByAppendingPathComponent:NSStringFromClass(self)];
}

+ (void)_enumerateImageCachesUsingBlock:(void (^)(DCTImageCache *imageCache, BOOL *stop))block {
	NSFileManager *fileManager = [NSFileManager new];
	NSString *cachePath = [[self class] _defaultCachePath];
	NSArray *caches = [[fileManager contentsOfDirectoryAtPath:cachePath error:nil] copy];
	
	[caches enumerateObjectsUsingBlock:^(NSString *name, NSUInteger i, BOOL *stop) {
		DCTImageCache *imageCache = [DCTImageCache imageCacheWithName:name];
		block(imageCache, stop);
	}];
}

@end

#pragma mark -

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

#pragma mark -


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
	dispatch_sync([self queue], ^{
		_path = [path copy];
		_hashStore = [[DCTInternalImageCacheHashStore alloc] initWithPath:[self hashesPath]];
		_fileManager = [NSFileManager new];
		[_fileManager createDirectoryAtPath:_path withIntermediateDirectories:YES attributes:nil error:nil];
	});
	return self;
}

- (void)removeAllImages {
	dispatch_async(self.queue, ^{
		[_fileManager removeItemAtPath:_path error:nil];
		[_fileManager createDirectoryAtPath:_path withIntermediateDirectories:YES attributes:nil error:nil];
	});
}

- (void)removeImageForKey:(NSString *)key size:(CGSize)size {
	dispatch_async(self.queue, ^{
		NSString *path = [self pathForKey:key size:size];
		[_fileManager removeItemAtPath:path error:nil];
	});
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
	NSArray *filenames = [[_fileManager contentsOfDirectoryAtPath:_path error:nil] copy];
	[filenames enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger i, BOOL *stop) {
		NSString *key = [_hashStore keyForHash:filename];
		block(key, stop);
	}];
}

- (void)enumerateSizesForKey:(NSString *)key usingBlock:(void (^)(CGSize size, BOOL *stop))block {
	NSArray *filenames = [[_fileManager contentsOfDirectoryAtPath:[self pathForKey:key] error:nil] copy];
	[filenames enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger i, BOOL *stop) {
		block(CGSizeFromString(filename), stop);
	}];
}

#pragma mark Internal

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

@implementation UIImage (DCTImageCache)

- (void)dctImageCache_decompress {
	CGImageRef imageRef = [self CGImage];
	CGColorSpaceRef colorspace = CGImageGetColorSpace(imageRef);
	CGContextRef context = CGBitmapContextCreate(NULL, 1, 1, 8, 4, colorspace, kCGImageAlphaNoneSkipFirst);
	CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), imageRef);
	CGContextRelease(context);
}

@end

