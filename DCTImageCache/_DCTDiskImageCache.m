//
//  _DCTDiskImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTDiskImageCache.h"
#import "_DCTImageCacheItem.h"
#import "NSOperationQueue+_DCTImageCache.h"
#import <CoreData/CoreData.h>

#import "_DCTImageCacheOperation.h"

@implementation _DCTDiskImageCache {
	NSURL *_storeURL;
	NSManagedObjectContext *_managedObjectContext;
	NSOperationQueue *_queue;
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
	_queue = [[NSOperationQueue alloc] init];
	_queue.name = NSStringFromClass([self class]);
	_queue.maxConcurrentOperationCount = 1;
	[_queue addOperationWithBlock:^{
		[self _createStack];
	}];
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

	_managedObjectContext = [NSManagedObjectContext new];
	_managedObjectContext.persistentStoreCoordinator = coordinator;
}

- (_DCTImageCacheOperation *)setImageOperationWithKey:(NSString *)key size:(CGSize)size {
	return [_queue dctImageCache_operationOfType:_DCTImageCacheOperationTypeSet withKey:key size:size];
}

- (_DCTImageCacheOperation *)setImageOperationWithImage:(UIImage *)image forKey:(NSString *)key size:(CGSize)size {
	_DCTImageCacheOperation *operation = [_DCTImageCacheOperation setOperationWithKey:key size:size image:image block:^{
		_DCTImageCacheItem *item = [_DCTImageCacheItem insertInManagedObjectContext:_managedObjectContext];
		item.key = key;
		item.sizeString = NSStringFromCGSize(size);
		item.imageData = UIImagePNGRepresentation(image);
		item.date = [NSDate new];
		[self _setNeedsSave];
	}];
	operation.queuePriority = NSOperationQueuePriorityLow;
	[_queue addOperation:operation];
	return operation;
}

- (_DCTImageCacheOperation *)fetchImageOperationForKey:(NSString *)key size:(CGSize)size {
	_DCTImageCacheOperation *operation = [_queue dctImageCache_operationOfType:_DCTImageCacheOperationTypeFetch withKey:key size:size];
	if (!operation) {
		operation = [_DCTImageCacheOperation fetchOperationWithKey:key size:size block:^(void(^completion)(UIImage *)) {
			NSFetchRequest *fetchRequest = [self _fetchRequestForKey:key size:size];
			NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
			_DCTImageCacheItem *item = [items lastObject];
			completion([UIImage imageWithData:item.imageData]);
		}];
		operation.queuePriority = NSOperationQueuePriorityVeryHigh;
		[_queue addOperation:operation];
	}
	return operation;
}

- (_DCTImageCacheOperation *)hasImageOperationForKey:(NSString *)key size:(CGSize)size {
	_DCTImageCacheOperation *operation = [_queue dctImageCache_operationOfType:_DCTImageCacheOperationTypeHasImage withKey:key size:size];
	if (!operation) {
		operation = [_DCTImageCacheOperation hasImageOperationWithKey:key size:size block:^(void(^completion)(BOOL)) {
			NSFetchRequest *fetchRequest = [self _fetchRequestForKey:key size:size];
			NSUInteger count = [_managedObjectContext countForFetchRequest:fetchRequest error:NULL];
			BOOL hasImage = (count > 0);
			completion(hasImage);
		}];
		operation.queuePriority = NSOperationQueuePriorityHigh;
		[_queue addOperation:operation];
	}
	return operation;
}

- (void)removeAllImages {
	[_queue addOperationWithBlock:^{
		[[NSFileManager defaultManager] removeItemAtURL:_storeURL error:NULL];
		[self _createStack];
	}];
}

- (void)removeImageForKey:(NSString *)key size:(CGSize)size {
	[_queue addOperationWithBlock:^{
		NSFetchRequest *fetchRequest = [self _fetchRequestForKey:key size:size];
		NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
		for (_DCTImageCacheItem *item in items) [_managedObjectContext deleteObject:item];
		[self _setNeedsSave];
	}];
}

- (void)removeAllImagesForKey:(NSString *)key {
	[_queue addOperationWithBlock:^{
		NSFetchRequest *fetchRequest = [self _fetchRequestForKey:key];
		NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
		for (_DCTImageCacheItem *item in items) [_managedObjectContext deleteObject:item];
		[self _setNeedsSave];
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

- (void)_setNeedsSave {
	_DCTImageCacheOperation *operation = [_queue dctImageCache_operationOfType:_DCTImageCacheOperationTypeSave];
	if (operation) return;

	operation = [_DCTImageCacheOperation saveOperationWithBlock:^{
		[_managedObjectContext save:NULL];
	}];
	operation.queuePriority = NSOperationQueuePriorityVeryLow;
	[_queue addOperation:operation];
}

@end
