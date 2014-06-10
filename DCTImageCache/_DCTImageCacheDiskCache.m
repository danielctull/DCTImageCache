//
//  _DCTDiskImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

@import CoreData;
#import "_DCTImageCacheDiskCache.h"
#import "_DCTImageCacheItem.h"

static NSString *const _DCTImageCacheDiskCacheModelName = @"DCTImageCache";
static NSString *const _DCTImageCacheDiskCacheModelExtension = @"momd";

@interface _DCTImageCacheDiskCache ()
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, weak) NSOperation *saveOperation;
@end

@implementation _DCTImageCacheDiskCache

- (id)initWithStoreURL:(NSURL *)storeURL {
	if (!(self = [super init])) return nil;
	_storeURL = [storeURL copy];
	_queue = [[NSOperationQueue alloc] init];
	_queue.name = NSStringFromClass([self class]);
	_queue.maxConcurrentOperationCount = 1;
	[_queue addOperationWithBlock:^{
		[self createStack];
	}];
	return self;
}

- (void)createStack {
	NSURL *modelURL = [[DCTImageCache _bundle] URLForResource:_DCTImageCacheDiskCacheModelName withExtension:_DCTImageCacheDiskCacheModelExtension];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *storeDirectoryURL = [self.storeURL URLByDeletingLastPathComponent];
	[fileManager createDirectoryAtURL:storeDirectoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
	NSDictionary *storeOptions = @{ NSSQLitePragmasOption : @{ @"journal_mode" : @"WAL" } };
	if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:storeOptions error:NULL]) {
		[fileManager removeItemAtURL:self.storeURL error:NULL];
		[coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:storeOptions error:NULL];
	}

	self.managedObjectContext = [NSManagedObjectContext new];
	self.managedObjectContext.persistentStoreCoordinator = coordinator;
}

- (void)hasImageWithAttributes:(DCTImageCacheAttributes *)attributes
					   handler:(_DCTImageCacheHasImageHandler)handler {

	NSParameterAssert(attributes);
	NSParameterAssert(handler);

	[self performOperationWithPriority:NSOperationQueuePriorityVeryHigh cancellable:YES block:^{
		NSFetchRequest *fetchRequest = [attributes _fetchRequest];
		NSError *error;
		NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
		handler(count > 0, error);
	}];
}

- (void)setImage:(DCTImageCacheImage *)image
   forAttributes:(DCTImageCacheAttributes *)attributes {

	NSParameterAssert(image);
	NSParameterAssert(attributes);

	[self performOperationWithPriority:NSOperationQueuePriorityVeryHigh cancellable:NO block:^{
		_DCTImageCacheItem *item = [_DCTImageCacheItem insertInManagedObjectContext:self.managedObjectContext];
		[attributes _setupCacheItemProperties:item];
		item.imageData = [NSKeyedArchiver archivedDataWithRootObject:image];
		item.date = [NSDate new];
		[self.managedObjectContext save:NULL];
		[self.managedObjectContext refreshObject:item mergeChanges:NO];
	}];
}

- (void)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes
						 handler:(DCTImageCacheImageHandler)handler {

	NSParameterAssert(attributes);
	NSParameterAssert(handler);

	[self performOperationWithPriority:NSOperationQueuePriorityVeryHigh cancellable:YES block:^{
		NSFetchRequest *fetchRequest = [attributes _fetchRequest];
		fetchRequest.fetchLimit = 1;
		NSError *error;
		DCTImageCacheImage *image;
		NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		_DCTImageCacheItem *item = [items lastObject];
		if (item) {
			image = [NSKeyedUnarchiver unarchiveObjectWithData:item.imageData];
			[self.managedObjectContext refreshObject:item mergeChanges:NO];
		}
		handler(image, error);
	}];
}

- (void)removeAllImages {
	[self performOperationWithPriority:NSOperationQueuePriorityVeryHigh cancellable:NO block:^{
		[[NSFileManager defaultManager] removeItemAtURL:self.storeURL error:NULL];
		[self createStack];
	}];
}

- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes {
	[self performOperationWithPriority:NSOperationQueuePriorityVeryHigh cancellable:NO block:^{
		NSFetchRequest *fetchRequest = [attributes _fetchRequest];
		NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
		for (_DCTImageCacheItem *item in items) [self.managedObjectContext deleteObject:item];
		[self.managedObjectContext save:NULL];
	}];
}

- (void)performOperationWithPriority:(NSOperationQueuePriority)priority cancellable:(BOOL)cancellable block:(void(^)())block {

	NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		[progress becomeCurrentWithPendingUnitCount:1];
		block();
		[progress resignCurrent];
	}];

	if (cancellable) {
		progress.cancellationHandler = ^{
			[operation cancel];
		};
	}

	operation.queuePriority = priority;
	[self.queue addOperation:operation];
}

@end
