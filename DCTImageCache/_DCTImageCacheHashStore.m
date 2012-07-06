//
//  _DCTImageCacheHashStore.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "_DCTImageCacheHashStore.h"

@implementation _DCTImageCacheHashStore {
	__strong NSMutableDictionary *_keyToHashDictionary;
	__strong NSString *_keyToHashPath;
	__strong NSMutableDictionary *_hashToKeyDictionary;
	__strong NSString *_hashToKeyPath;
}

- (id)initWithPath:(NSString *)path {
	if (!(self = [super init])) return nil;
	_hashToKeyPath = [path stringByAppendingPathComponent:@"hashToKey"];
	_keyToHashPath = [path stringByAppendingPathComponent:@"keyToHash"];
	_hashToKeyDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:_hashToKeyPath];
	_keyToHashDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:_keyToHashPath];
	if (!_hashToKeyDictionary) _hashToKeyDictionary = [NSMutableDictionary new];
	if (!_keyToHashDictionary) _keyToHashDictionary = [NSMutableDictionary new];
	return self;
}

- (void)storeKey:(NSString *)key forHash:(NSString *)hash {
	if ([key length] == 0) return;
	if ([[_keyToHashDictionary allKeys] containsObject:hash]) return;
	
	[_keyToHashDictionary setObject:hash forKey:key];
	[_keyToHashDictionary writeToFile:_keyToHashPath atomically:YES];
	[_hashToKeyDictionary setObject:key forKey:hash];
	[_hashToKeyDictionary writeToFile:_hashToKeyPath atomically:YES];
}

- (BOOL)containsHashForKey:(NSString *)key {
	return [[_keyToHashDictionary allKeys] containsObject:key];
}

- (NSString *)keyForHash:(NSString *)hash {
	return [_hashToKeyDictionary objectForKey:hash];
}

- (NSString *)hashForKey:(NSString *)key {

	NSString *hash = [_keyToHashDictionary objectForKey:key];
	if (!hash) {
		hash = [[NSProcessInfo processInfo] globallyUniqueString];
		[self storeKey:key forHash:hash];
	}
	return hash;
}

- (void)removeHashForKey:(NSString *)key {
	if ([key length] == 0) return;
	
	NSString *hash = [self hashForKey:key];
	[_keyToHashDictionary removeObjectForKey:key];
	[_keyToHashDictionary writeToFile:_keyToHashPath atomically:YES];
	[_hashToKeyDictionary removeObjectForKey:hash];
	[_hashToKeyDictionary writeToFile:_hashToKeyPath atomically:YES];
}

@end
