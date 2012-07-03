//
//  _DCTImageCacheHashStore.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheHashStore.h"

@implementation _DCTImageCacheHashStore {
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
