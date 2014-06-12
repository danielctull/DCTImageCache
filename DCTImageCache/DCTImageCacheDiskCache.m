//
//  _DCTDiskImageCache.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

@import CoreData;
#import "DCTImageCacheDiskCache.h"
#import "DCTImageCacheItem.h"

static NSString *const DCTImageCacheDiskCacheModelName = @"DCTImageCache";
static NSString *const DCTImageCacheDiskCacheModelExtension = @"momd";
static NSString *const DCTImageCacheDiskCacheStoreName = @"metadata";

@interface DCTImageCacheDiskCache ()
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSOperationQueue *queue;
@property (nonatomic) NSFileManager *fileManager;
@property (nonatomic, readonly) NSURL *storeURL;
@end

@implementation DCTImageCacheDiskCache

- (id)initWithURL:(NSURL *)URL {
	self = [self init];
	if (!self) return nil;
	_URL = [URL copy];
	_storeURL = [_URL URLByAppendingPathComponent:DCTImageCacheDiskCacheStoreName];
	_fileManager = [NSFileManager new];
	_queue = [NSOperationQueue new];
	_queue.name = NSStringFromClass([self class]);
	_queue.maxConcurrentOperationCount = 1;
	[_queue addOperationWithBlock:^{
		[self createStack];
	}];
	return self;
}

- (void)createStack {
	NSURL *modelURL = [[DCTImageCache bundle] URLForResource:DCTImageCacheDiskCacheModelName withExtension:DCTImageCacheDiskCacheModelExtension];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	[self.fileManager createDirectoryAtURL:self.URL withIntermediateDirectories:YES attributes:nil error:NULL];
	NSDictionary *storeOptions = @{ NSSQLitePragmasOption : @{ @"journal_mode" : @"WAL" } };
	if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:storeOptions error:NULL]) {
		[self.fileManager removeItemAtURL:self.storeURL error:NULL];
		[coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:storeOptions error:NULL];
	}

	self.managedObjectContext = [NSManagedObjectContext new];
	self.managedObjectContext.persistentStoreCoordinator = coordinator;
}

- (void)hasImageWithAttributes:(DCTImageCacheAttributes *)attributes
					   handler:(DCTImageCacheHasImageHandler)handler {

	NSParameterAssert(attributes);
	NSParameterAssert(handler);

	[self performOperationWithPriority:NSOperationQueuePriorityVeryHigh cancellable:YES block:^{
		NSFetchRequest *fetchRequest = [self fetchRequestFromAttributes:attributes];
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

		NSDate *date = [NSDate new];
		NSString *identifier = [[NSUUID UUID] UUIDString];

		DCTImageCacheItem *item = [DCTImageCacheItem insertInManagedObjectContext:self.managedObjectContext];
		item.key = attributes.key;
		item.sizeString = attributes.sizeString;
		item.scale = @(attributes.scale);
		item.creationDate = date;
		item.lastAccessedDate = date;
		item.identifier = identifier;

		NSURL *URL = [self.URL URLByAppendingPathComponent:identifier];
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:image];
		[self.fileManager createFileAtPath:URL.path contents:data attributes:nil];

		[self.managedObjectContext save:NULL];
	}];
}

- (void)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes
						 handler:(DCTImageCacheImageHandler)handler {

	NSParameterAssert(attributes);
	NSParameterAssert(handler);

	[self performOperationWithPriority:NSOperationQueuePriorityVeryHigh cancellable:YES block:^{

		NSFetchRequest *fetchRequest = [self fetchRequestFromAttributes:attributes];
		fetchRequest.fetchLimit = 1;
		NSError *error;
		DCTImageCacheImage *image;
		NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		DCTImageCacheItem *item = [items lastObject];
		item.lastAccessedDate = [NSDate new];

		if (item) {
			NSString *identifier = item.identifier;
			NSURL *URL = [self.URL URLByAppendingPathComponent:identifier];
			NSData *data = [self.fileManager contentsAtPath:URL.path];
			if (data) {
				image = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			} else {
				[self.managedObjectContext deleteObject:item];
			}
			[self.managedObjectContext save:NULL];
		}

		handler(image, error);
	}];
}

- (void)removeAllImages {
	[self performOperationWithPriority:NSOperationQueuePriorityVeryHigh cancellable:NO block:^{
		[[NSFileManager defaultManager] removeItemAtURL:self.URL error:NULL];
		[self createStack];
	}];
}

- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes {
	[self performOperationWithPriority:NSOperationQueuePriorityVeryHigh cancellable:NO block:^{
		NSFetchRequest *fetchRequest = [self fetchRequestFromAttributes:attributes];
		NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
		for (DCTImageCacheItem *item in items) {
			NSURL *URL = [self.URL URLByAppendingPathComponent:item.identifier];
			[self.fileManager removeItemAtURL:URL error:NULL];
			[self.managedObjectContext deleteObject:item];
		}
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

- (NSFetchRequest *)fetchRequestFromAttributes:(DCTImageCacheAttributes *)attributes {
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[DCTImageCacheItem entityName]];

	NSMutableArray *predicates = [[NSMutableArray alloc] initWithCapacity:3];

	NSString *key = attributes.key;
	if (key.length > 0) {
		NSPredicate *keyPredicate = [NSPredicate predicateWithFormat:@"%K == %@", DCTImageCacheItemAttributes.key, key];
		[predicates addObject:keyPredicate];
	}

	CGFloat scale = attributes.scale;
	NSPredicate *scalePredicate = [NSPredicate predicateWithFormat:@"%K == %@", DCTImageCacheItemAttributes.scale, @(scale)];
	[predicates addObject:scalePredicate];

	NSString *sizeString = attributes.sizeString;
	if (sizeString.length > 0) {
		NSPredicate *sizePredicate = [NSPredicate predicateWithFormat:@"%K == %@", DCTImageCacheItemAttributes.sizeString, sizeString];
		[predicates addObject:sizePredicate];
	}

	NSDate *createdBefore = attributes.createdBefore;
	if (createdBefore) {
		NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"%K < %@", DCTImageCacheItemAttributes.creationDate, createdBefore];
		[predicates addObject:datePredicate];
	}

	fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	return fetchRequest;
}

@end
