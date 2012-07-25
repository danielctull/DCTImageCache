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
	__strong NSOperationQueue *_queue;
}

- (id)initWithPath:(NSString *)path {
	if (!(self = [super init])) return nil;
	
	_queue = [NSOperationQueue new];
	[_queue setMaxConcurrentOperationCount:1];
	
	[self _performBlock:^{
		_path = [path copy];
		_hashStore = [[_DCTImageCacheHashStore alloc] initWithPath:path];
		_fileManager = [NSFileManager new];
		[_fileManager createDirectoryAtPath:_path withIntermediateDirectories:YES attributes:nil error:nil];
	}];
	
	return self;
}

- (void)removeAllImages {
	[self _performBlock:^{
		[_fileManager removeItemAtPath:_path error:nil];
		[_fileManager createDirectoryAtPath:_path withIntermediateDirectories:YES attributes:nil error:nil];
	}];
}

- (void)removeImageForKey:(NSString *)key size:(CGSize)size {
	[self _performBlock:^{
		NSString *path = [self _pathForKey:key size:size];
		[_fileManager removeItemAtPath:path error:nil];
	}];
}

- (void)removeAllImagesForKey:(NSString *)key {
	[self _performBlock:^{
		[_hashStore removeHashForKey:key];
		NSString *directoryPath = [self _pathForKey:key];
		[_fileManager removeItemAtPath:directoryPath error:nil];
	}];
}

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size {
	
	__block UIImage *image = nil;
	
	[self _performBlockAndWait:^{
		image = [self _imageForKey:key size:size];
	}];
	
	return image;
}

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size {
	
	__block BOOL hasImage = NO;
	
	[self _performBlockAndWait:^{
		NSString *imagePath = [self _pathForKey:key size:size];
		hasImage = [_fileManager fileExistsAtPath:imagePath];
	}];
	
	return hasImage;	
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void (^)(UIImage *))handler {
	[self _performBlock:^{
		UIImage *image = [self _imageForKey:key size:size];
		handler(image);
	}];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	[self _performBlock:^{
		NSString *path = [self _pathForKey:key];
		NSString *imagePath = [self _pathForKey:key size:size];
		
		if (![_fileManager fileExistsAtPath:path])
			[_fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];

		[NSKeyedArchiver archiveRootObject:image toFile:imagePath];
	}];
}

- (void)fetchAttributesForImageWithKey:(NSString *)key size:(CGSize)size handler:(void (^)(NSDictionary *))handler {
	[self _performBlock:^{
		NSString *path = [self _pathForKey:key size:size];
		NSDictionary *dictionary = [_fileManager attributesOfItemAtPath:path error:nil];
		handler(dictionary);
	}];
}

- (void)enumerateKeysUsingBlock:(void (^)(NSString *key, BOOL *stop))block {
	[self _performBlock:^{
		NSArray *filenames = [[_fileManager contentsOfDirectoryAtPath:_path error:nil] copy];
		[filenames enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger i, BOOL *stop) {
			NSString *key = [_hashStore keyForHash:filename];
			block(key, stop);
		}];
	}];
}

- (void)enumerateSizesForKey:(NSString *)key usingBlock:(void (^)(CGSize size, BOOL *stop))block {
	[self _performBlock:^{
		NSArray *filenames = [[_fileManager contentsOfDirectoryAtPath:[self _pathForKey:key] error:nil] copy];
		[filenames enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger i, BOOL *stop) {
			block(CGSizeFromString(filename), stop);
		}];
	}];
}

#pragma mark Internal

- (void)_performBlock:(void(^)())block {
	[_queue addOperationWithBlock:block];
}

- (void)_performBlockAndWait:(void(^)())block {
	NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:block];
	[blockOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	[_queue addOperation:blockOperation];
	[blockOperation waitUntilFinished];
}

- (UIImage *)_imageForKey:(NSString *)key size:(CGSize)size {
	NSString *imagePath = [self _pathForKey:key size:size];
	return [NSKeyedUnarchiver unarchiveObjectWithFile:imagePath];
}

- (NSString *)_pathForKey:(NSString *)key size:(CGSize)size {
	NSString *path = [self _pathForKey:key];
	return [path stringByAppendingPathComponent:NSStringFromCGSize(size)];
}

- (NSString *)_pathForKey:(NSString *)key {
	NSString *hash = [_hashStore hashForKey:key];
	return [_path stringByAppendingPathComponent:hash];
}

@end
