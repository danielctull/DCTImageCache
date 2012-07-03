//
//  _DCTDiskImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTDiskImageCache.h"
#import "_DCTImageCacheHashStore.h"

@implementation _DCTDiskImageCache {
	__strong NSString *_path;
	__strong _DCTImageCacheHashStore *_hashStore;
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
		_hashStore = [[_DCTImageCacheHashStore alloc] initWithPath:[self hashesPath]];
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
