//
//  _DCTDiskImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "_DCTImageCacheDiskCache.h"
#import "_DCTImageCacheItem.h"
#import "_DCTImageCacheOperation.h"

typedef enum : NSInteger {
	_DCTImageCacheDiskCachePrioritySave = NSOperationQueuePriorityVeryLow,
	_DCTImageCacheDiskCachePrioritySet = NSOperationQueuePriorityLow,
	_DCTImageCacheDiskCachePriorityHasImage = NSOperationQueuePriorityLow,
	_DCTImageCacheDiskCachePriorityFetch = NSOperationQueuePriorityNormal,
	_DCTImageCacheDiskCachePrioritySaveMemoryWarning = NSOperationQueuePriorityHigh,
	_DCTImageCacheDiskCachePrioritySetMemoryWarning = NSOperationQueuePriorityVeryHigh
} _DCTImageCacheDiskCachePriority;

NSString *const _DCTImageCacheDiskCacheModelName = @"DCTImageCache";
NSString *const _DCTImageCacheDiskCacheModelExtension = @"momd";

@implementation _DCTImageCacheDiskCache {
	NSManagedObjectContext *_managedObjectContext;
	NSOperationQueue *_queue;
	__weak _DCTImageCacheOperation *_saveOperation;
}

- (id)initWithStoreURL:(NSURL *)storeURL {
	if (!(self = [super init])) return nil;
	_storeURL = [storeURL copy];
	_queue = [[NSOperationQueue alloc] init];
	_queue.name = NSStringFromClass([self class]);
	_queue.maxConcurrentOperationCount = 1;
	[_queue addOperationWithBlock:^{
		[self _createStack];
	}];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)_didReceiveMemoryWarningNotification:(NSNotification *)notification {
	[_queue.operations enumerateObjectsUsingBlock:^(_DCTImageCacheOperation *operation, NSUInteger i, BOOL *stop) {

		if (![operation isKindOfClass:[_DCTImageCacheOperation class]]) return;

		if (operation.type == _DCTImageCacheOperationTypeSet)
			operation.queuePriority = _DCTImageCacheDiskCachePrioritySetMemoryWarning;

		else if (operation.type == _DCTImageCacheOperationTypeSave)
			operation.queuePriority = _DCTImageCacheDiskCachePrioritySaveMemoryWarning;
	}];
}

- (void)_createStack {
	NSURL *modelURL = [[DCTImageCache _bundle] URLForResource:_DCTImageCacheDiskCacheModelName
												withExtension:_DCTImageCacheDiskCacheModelExtension];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *storeDirectoryURL = [self.storeURL URLByDeletingLastPathComponent];
	[fileManager createDirectoryAtURL:storeDirectoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
	if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:NULL]) {
		[fileManager removeItemAtURL:self.storeURL error:NULL];
		[coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:NULL];
	}

	_managedObjectContext = [NSManagedObjectContext new];
	_managedObjectContext.persistentStoreCoordinator = coordinator;
}

- (UIImage *)imageWithAttributes:(DCTImageCacheAttributes *)attributes {
	_DCTImageCacheOperation *operation = [_DCTImageCacheOperation operationWithType:_DCTImageCacheOperationTypeSet attributes:attributes onQueue:_queue];
	_DCTImageCacheProcessManager *processManager = [_DCTImageCacheProcessManager processManagerForProcess:operation];
	return processManager.image;
}

- (id<DCTImageCacheProcess>)hasImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(_DCTImageCacheHasImageHandler)handler {

	if (handler == NULL) return nil;

	_DCTImageCacheOperation *operation = [_DCTImageCacheOperation operationWithType:_DCTImageCacheOperationTypeSet attributes:attributes onQueue:_queue];
	if (operation) {
		handler(YES, nil);
		return nil;
	}
	
	operation = [_DCTImageCacheOperation operationWithType:_DCTImageCacheOperationTypeHasImage attributes:attributes onQueue:_queue];
	_DCTImageCacheProcessManager *processManager = [_DCTImageCacheProcessManager processManagerForProcess:operation];

	if (!processManager) {
		operation = [_DCTImageCacheOperation new];
		processManager = [_DCTImageCacheProcessManager new];
		processManager.process = operation;
		operation.uniqueIdentifier = attributes.identifier;
		operation.queuePriority = _DCTImageCacheDiskCachePriorityHasImage;
		operation.block = ^{
			NSFetchRequest *fetchRequest = [attributes _fetchRequest];
			NSUInteger count = [_managedObjectContext countForFetchRequest:fetchRequest error:NULL];
			processManager.hasImage = (count > 0);
		};
		[_queue addOperation:operation];
	}

	_DCTImageCacheCancelProxy *cancelProxy = [_DCTImageCacheCancelProxy new];
	cancelProxy.hasImageHandler = handler;
	[processManager addCancelProxy:cancelProxy];

	return cancelProxy;
}

- (id<DCTImageCacheProcess>)setImage:(UIImage *)image forAttributes:(DCTImageCacheAttributes *)attributes {

	_DCTImageCacheOperation *operation = [_DCTImageCacheOperation operationWithType:_DCTImageCacheOperationTypeSet attributes:attributes onQueue:_queue];
	[operation cancel];

	__weak _DCTImageCacheDiskCache *weakSelf = self;

	operation = [_DCTImageCacheOperation new];
	operation.uniqueIdentifier = attributes.identifier;
	operation.block = ^{
		_DCTImageCacheItem *item = [_DCTImageCacheItem insertInManagedObjectContext:_managedObjectContext];
		[attributes _setupCacheItemProperties:item];
		item.imageData = [NSKeyedArchiver archivedDataWithRootObject:image];
		item.date = [NSDate new];
		[weakSelf _setNeedsSave];
	};
	operation.queuePriority = _DCTImageCacheDiskCachePrioritySet;
	[_queue addOperation:operation];
	return operation;
}

- (id<DCTImageCacheProcess>)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler {

	_DCTImageCacheOperation *operation = [_DCTImageCacheOperation operationWithType:_DCTImageCacheOperationTypeFetch attributes:attributes onQueue:_queue];
	_DCTImageCacheProcessManager *processManager = [_DCTImageCacheProcessManager processManagerForProcess:operation];

	if (!processManager) {
		processManager = [_DCTImageCacheProcessManager new];
		operation = [_DCTImageCacheOperation new];
		processManager.process = operation;
		operation.uniqueIdentifier = attributes.identifier;
		operation.block = ^{
			NSFetchRequest *fetchRequest = [attributes _fetchRequest];
			fetchRequest.fetchLimit = 1;
			NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
			_DCTImageCacheItem *item = [items lastObject];
			processManager.image = [NSKeyedUnarchiver unarchiveObjectWithData:item.imageData];
		};
		operation.queuePriority = _DCTImageCacheDiskCachePriorityFetch;
		[_queue addOperation:operation];
	}

	_DCTImageCacheCancelProxy *cancelProxy = [_DCTImageCacheCancelProxy new];
	cancelProxy.imageHandler = handler;
	[processManager addCancelProxy:cancelProxy];

	return cancelProxy;
}

- (void)removeAllImages {
	[_queue addOperationWithBlock:^{
		[[NSFileManager defaultManager] removeItemAtURL:self.storeURL error:NULL];
		[self _createStack];
	}];
}

- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes {
	[_queue addOperationWithBlock:^{
		NSFetchRequest *fetchRequest = [attributes _fetchRequest];
		NSArray *items = [_managedObjectContext executeFetchRequest:fetchRequest error:NULL];
		for (_DCTImageCacheItem *item in items) [_managedObjectContext deleteObject:item];
		[self _setNeedsSave];
	}];
}

- (void)_setNeedsSave {
	if (_saveOperation) return;
	
	_DCTImageCacheOperation *saveOperation = [_DCTImageCacheOperation new];
	saveOperation.block = ^{
		[_managedObjectContext save:NULL];
	};
	saveOperation.queuePriority = _DCTImageCacheDiskCachePrioritySave;
	[_queue addOperation:saveOperation];
	_saveOperation = saveOperation;
}

@end
