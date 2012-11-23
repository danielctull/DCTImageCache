//
//  _DCTDiskImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTDiskImageCache.h"
#import "_DCTImageCacheItem.h"
#import <CoreData/CoreData.h>

@implementation _DCTDiskImageCache {
	NSURL *_storeURL;
	NSManagedObjectContext *_managedObjectContext;
	NSManagedObjectContext *_savingContext;
	NSManagedObjectContext *_fetchingContext;
}

+ (NSBundle *)bundle {
	static NSBundle *bundle;
	static dispatch_once_t bundleToken;
	dispatch_once(&bundleToken, ^{
		NSDirectoryEnumerator *enumerator = [[NSFileManager new] enumeratorAtURL:[[NSBundle mainBundle] bundleURL]
													  includingPropertiesForKeys:nil
																		 options:NSDirectoryEnumerationSkipsHiddenFiles
																	errorHandler:NULL];

		for (NSURL *URL in enumerator)
			if ([[URL lastPathComponent] isEqualToString:@"DCTImageCache.bundle"])
				bundle = [NSBundle bundleWithURL:URL];
	});

	return bundle;
}

- (id)initWithPath:(NSString *)path {
	if (!(self = [super init])) return nil;
	_storeURL = [[[NSURL alloc] initFileURLWithPath:path] URLByAppendingPathComponent:@"store"];
	[self _createStack];
	return self;
}

- (void)_createStack {
	NSURL *modelURL = [[[self class] bundle] URLForResource:@"DCTImageCache" withExtension:@"momd"];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	[[NSFileManager defaultManager] createDirectoryAtURL:[_storeURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
	if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:_storeURL options:nil error:NULL]) {
		[[NSFileManager defaultManager] removeItemAtURL:_storeURL error:NULL];
		[coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:_storeURL options:nil error:NULL];
	}

	_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	_managedObjectContext.persistentStoreCoordinator = coordinator;

	_savingContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	_savingContext.parentContext = _managedObjectContext;

	_fetchingContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	_fetchingContext.parentContext = _managedObjectContext;
}

- (void)removeAllImages {
	[[NSFileManager defaultManager] removeItemAtURL:_storeURL error:NULL];
	[self _createStack];
}

- (void)removeImageForKey:(NSString *)key size:(CGSize)size {
	[_managedObjectContext performBlock:^{
		NSFetchRequest *fetchRequest = [self _fetchRequestForKey:key size:size];
		NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
		for (_DCTImageCacheItem *item in items)
			[_managedObjectContext deleteObject:item];
		[_managedObjectContext save:NULL];
	}];
}

- (void)removeAllImagesForKey:(NSString *)key {
	[_managedObjectContext performBlock:^{
		NSFetchRequest *fetchRequest = [self _fetchRequestForKey:key];
		NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
		for (_DCTImageCacheItem *item in items)
			[_managedObjectContext deleteObject:item];
		[_managedObjectContext save:NULL];
	}];
}

- (UIImage *)imageForKey:(NSString *)key size:(CGSize)size {
	__block UIImage *image;
	[_managedObjectContext performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [self _fetchRequestForKey:key size:size];
		NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
		_DCTImageCacheItem *item = [items lastObject];
		image = [UIImage imageWithData:item.imageData];
	}];
	return image;
}

- (BOOL)hasImageForKey:(NSString *)key size:(CGSize)size {
	__block BOOL hasImage = NO;
	[_managedObjectContext performBlockAndWait:^{
		NSFetchRequest *fetchRequest = [self _fetchRequestForKey:key size:size];
		NSUInteger count = [_managedObjectContext countForFetchRequest:fetchRequest error:NULL];
		hasImage = count > 0;
	}];
	return hasImage;
}

- (void)fetchImageForKey:(NSString *)key size:(CGSize)size handler:(void (^)(UIImage *))handler {
	[_fetchingContext performBlock:^{
		NSFetchRequest *fetchRequest = [self _fetchRequestForKey:key size:size];
		NSArray *items = [_fetchingContext executeFetchRequest:fetchRequest error:NULL];
		_DCTImageCacheItem *item = [items lastObject];
		UIImage *image = [UIImage imageWithData:item.imageData];
		handler(image);
	}];
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	[_savingContext performBlock:^{
		_DCTImageCacheItem *item = [_DCTImageCacheItem insertInManagedObjectContext:_savingContext];
		item.key = key;
		item.sizeString = NSStringFromCGSize(size);
		item.imageData = UIImagePNGRepresentation(image);
		item.date = [NSDate new];
		[_savingContext save:NULL];
		[_managedObjectContext performBlock:^{
			[_managedObjectContext save:NULL];
		}];
	}];
}

- (NSFetchRequest *)_fetchRequestForKey:(NSString *)key {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[_DCTImageCacheItem entityName]];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@", _DCTImageCacheItemAttributes.key, key];
	return fetchRequest;
}

- (NSFetchRequest *)_fetchRequestForKey:(NSString *)key size:(CGSize)size {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[_DCTImageCacheItem entityName]];
	NSPredicate *keyPredicate = [NSPredicate predicateWithFormat:@"%K == %@", _DCTImageCacheItemAttributes.key, key];
	NSPredicate *sizePredicate = [NSPredicate predicateWithFormat:@"%K == %@", _DCTImageCacheItemAttributes.sizeString, NSStringFromCGSize(size)];
	fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[keyPredicate, sizePredicate]];
	return fetchRequest;
}

/*
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
}*/

@end
