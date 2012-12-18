//
//  DCTImageCache.h
//  DCTImageCache
//
//  Created by Daniel Tull on 25.05.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DCTImageCacheAttributes.h"

#ifndef dctimagecache
#define dctimagecache_1_0     10000
#define dctimagecache         dctimagecache_1_0
#endif


/** Generally used for an opaque object that forwards cancellation. */
@protocol DCTImageCacheProcess <NSObject>
/** Call this to cancel. */
- (void)cancel;
@end

@interface NSURLConnection (DCTImageCache) <DCTImageCacheProcess>
@end

@interface NSOperation (DCTImageCache) <DCTImageCacheProcess>
@end



/** Used for an opaque object that handles the saving of images to disk. */
@protocol DCTImageCacheCompletion <NSObject>
/** Set the image.
 @param image The image to save.
 */
- (void)finishWithImage:(UIImage *)image error:(NSError *)error;
@end


typedef void (^DCTImageCacheHandler)(NSError *);
typedef void (^DCTImageCacheImageHandler)(UIImage *, NSError *);

typedef id<DCTImageCacheProcess> (^DCTImageCacheFetcher)(DCTImageCacheAttributes *attributes, id<DCTImageCacheCompletion> completion);



@interface DCTImageCache : NSObject

/// @name 

+ (NSURL *)cacheDirectoryURL;

/// @name Initialization

/** Convience method to quickly get a default image cache.
 */
+ (instancetype)defaultImageCache;

/** Convience method to quickly get a default image cache.
 @param name The name of the image cache.
 */
+ (instancetype)imageCacheWithName:(NSString *)name;

/**
 @param storeURL
 */
+ (instancetype)imageCacheWithURL:(NSURL *)storeURL;

/** The location of the cache on disk.
 @return Location on disk.
 */
@property (nonatomic, copy, readonly) NSURL *storeURL;

/** The name of the cache. If imageCacheWithURL: was used, 
 the last path component of the URL is taken to be the name.
 @return The name of the cache.
 */
@property (nonatomic, copy, readonly) NSString *name;


/** This is a fetcher for images that should be set to download images from the Internet.
 */
@property (nonatomic, copy) DCTImageCacheFetcher imageFetcher;

/** Removes all images in the memory and disk caches. */
- (void)removeAllImages;

/** Removes all the images with the given attributes. */
- (void)removeImagesWithAttributes:(DCTImageCacheAttributes *)attributes;

/** Checks whether an image is found on disk with the given attributes, 
 if not the imageFetcher is executed to fetch the image. */
- (id<DCTImageCacheProcess>)prefetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheHandler)handler;

/** Retrieves an image with the given attributes, looking in the memory cache, 
 disk cache and finally calling the imageFetcher. 
 
 * Image is in memory (either the cache or waiting to be saved to disk):
 this method will return nil and the handler will be executed before this method returns.
 
 * Image is on disk: a fetch operation will be queued up and the handler
 will be executed on completion. You can call -cancel on the returned process object
 which will cancel the fetch and the handler will never be executed.
 
 * Image cannot be found on disk: the imageFetcher will be called and on completion
 of the fetch, the handler will be executed and the image will be stored on disk with the
 given attributes. You can call -cancel on the returned process object which will
 cancel the process returned from the imageFetcher and the handler will not be executed.
 
 The process object returned is not directly the request process that is spawned. Only one
 request process is created for each unique fetch, so the returned object acts as a proxy.
 Only once all proxy objects are cancelled will the actual request be cancelled.
 
 This is useful if you have images in a table view cell, which may be the same, you can call
 this method once per cell and if the cell goes offscreen, you can call cancel on the returned
 process object which will stop the handler being executed, but *not* affect other fetches for
 the same image.
 
 @param attributes The attributes for the image.
 @param handler The handler that should be executed with the fetched image.
 @return A process object that can be cancelled, preventing the handler from being executed.
 */
- (id<DCTImageCacheProcess>)fetchImageWithAttributes:(DCTImageCacheAttributes *)attributes handler:(DCTImageCacheImageHandler)handler;

@end
