//
//  DCTImageCache.m
//  Tweetville
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import "DCTImageCache.h"
#import "_DCTDiskImageCache.h"

@interface UIImage (DCTImageCache)
- (void)dctImageCache_decompress;
@end

#pragma mark -

@implementation DCTImageCache {
	__strong _DCTDiskImageCache *_diskCache;
	__strong NSCache *_memoryCache;
	__strong NSMutableDictionary *_imageHandlers;
	__strong NSOperationQueue *_queue;
}
@synthesize name = _name;
@synthesize imageFetcher = _imageFetcher;

#pragma mark NSObject

+ (void)initialize {
	@autoreleasepool {
		NSDate *now = [NSDate date];
		
		[self _enumerateImageCachesUsingBlock:^(DCTImageCache *imageCache, BOOL *stop) {
			
			_DCTDiskImageCache *diskCache = imageCache->_diskCache;
			[diskCache enumerateKeysUsingBlock:^(NSString *key, BOOL *stop) {
			
				[diskCache fetchAttributesForImageWithKey:key size:CGSizeZero handler:^(NSDictionary *attributes) {
				
					if (!attributes) {
						[diskCache removeAllImagesForKey:key];
						return;
					}
						
					NSDate *creationDate = [attributes objectForKey:NSFileCreationDate];
					NSTimeInterval timeInterval = [now timeIntervalSinceDate:creationDate];
					
					if (timeInterval > 604800) // 7 days
						[diskCache removeAllImagesForKey:key];
				}];
			}];
		}];
	}
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

- (id)_initWithName:(NSString *)name {
	if (!(self = [super init])) return nil;
	NSString *queueName = [NSString stringWithFormat:@"uk.co.danieltull.DCTImageCache.%@", name];
	_queue = [NSOperationQueue new];
	[_queue setMaxConcurrentOperationCount:1];
	[_queue setName:queueName];
	
	[_queue addOperationWithBlock:^{
		_name = [name copy];
		_memoryCache = [NSCache new];
		_imageHandlers = [NSMutableDictionary new];
		NSString *path = [[[self class] _defaultCachePath] stringByAppendingPathComponent:name];
		_diskCache = [[_DCTDiskImageCache alloc] initWithPath:path];
	}];
	
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
	[_diskCache removeAllImagesForKey:key];
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
	
	[_queue addOperationWithBlock:^{
		
		void (^handler)(UIImage *) = ^(UIImage *image) {
			if (theHandler != NULL) theHandler(image);
		};
		
		NSMutableArray *handlers = [self _imageHandlersForKey:key size:size];
		[handlers addObject:handler];
		
		if ([handlers count] > 1) return;
		
		__block BOOL saveToDisk = NO;
		void (^imageHandler)(UIImage *image) = ^(UIImage *image) {
			[_queue addOperationWithBlock:^{
				if (!image) return;
				[image dctImageCache_decompress];
				[_memoryCache setObject:image forKey:cacheKey];
				if (saveToDisk) [_diskCache setImage:image forKey:key size:size];
				[self _sendImage:image toHandlersForKey:key size:size];
			}];
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
	}];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	NSString *cacheKey = [self _cacheNameForKey:key size:size];
	[_memoryCache setObject:image forKey:cacheKey];
	[_diskCache setImage:image forKey:key size:size];
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


@implementation UIImage (DCTImageCache)

- (void)dctImageCache_decompress {
	CGImageRef imageRef = [self CGImage];
	size_t width = CGImageGetWidth(imageRef);
	size_t height = CGImageGetHeight(imageRef);
	CGSize size = CGSizeMake(width, height);
	UIGraphicsBeginImageContext(size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
	UIGraphicsEndImageContext();	
}

@end

