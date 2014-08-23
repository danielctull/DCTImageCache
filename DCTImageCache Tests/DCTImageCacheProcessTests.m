//
//  DCTImageCacheProcessTests.m
//  DCTImageCache
//
//  Created by Daniel Tull on 03.01.2013.
//  Copyright (c) 2013 Daniel Tull. All rights reserved.
//

#import "DCTImageCacheProcessTests.h"
#import "DCTImageCacheMockCancel.h"
#import "_DCTImageCacheProcessManager.h"

@implementation DCTImageCacheProcessTests

- (void)testCancel {

	__block BOOL cancelled = NO;

	DCTImageCacheMockCancel *process = [DCTImageCacheMockCancel new];
	process.cancellationBlock = ^{
		cancelled = YES;
	};
	
	_DCTImageCacheProcessManager *manager = [_DCTImageCacheProcessManager new];
	manager.process = process;

	_DCTImageCacheCancelProxy *proxy = [_DCTImageCacheCancelProxy new];
	[manager addCancelProxy:proxy];

	[proxy cancel];

	STAssertTrue(cancelled, @"Process should have been cancelled.");
}

- (void)testTwoCancel {

	__block BOOL cancelled = NO;

	DCTImageCacheMockCancel *process = [DCTImageCacheMockCancel new];
	process.cancellationBlock = ^{
		cancelled = YES;
	};

	_DCTImageCacheProcessManager *manager = [_DCTImageCacheProcessManager new];
	manager.process = process;

	_DCTImageCacheCancelProxy *proxy = [_DCTImageCacheCancelProxy new];
	[manager addCancelProxy:proxy];

	_DCTImageCacheCancelProxy *proxy2 = [_DCTImageCacheCancelProxy new];
	[manager addCancelProxy:proxy2];

	STAssertFalse(cancelled, @"Process should not have been cancelled.");

	[proxy cancel];

	STAssertFalse(cancelled, @"Process should not have been cancelled.");
	
	[proxy2 cancel];

	STAssertTrue(cancelled, @"Process should have been cancelled.");
}

- (void)testTwoProcessCancel {

	__block BOOL process1Cancelled = NO;
	__block BOOL process2Cancelled = NO;

	DCTImageCacheMockCancel *process1 = [DCTImageCacheMockCancel new];
	process1.cancellationBlock = ^{
		process1Cancelled = YES;
	};

	DCTImageCacheMockCancel *process2 = [DCTImageCacheMockCancel new];
	process2.cancellationBlock = ^{
		process2Cancelled = YES;
	};

	_DCTImageCacheProcessManager *manager1 = [_DCTImageCacheProcessManager new];
	manager1.process = process1;

	_DCTImageCacheProcessManager *manager2 = [_DCTImageCacheProcessManager new];
	manager2.process = process2;

	_DCTImageCacheCancelProxy *proxy = [_DCTImageCacheCancelProxy new];
	[manager1 addCancelProxy:proxy];
	[manager2 addCancelProxy:proxy];

	STAssertFalse(process1Cancelled, @"Process 1 should not have been cancelled.");
	STAssertFalse(process2Cancelled, @"Process 2 should not have been cancelled.");

	[proxy cancel];

	STAssertTrue(process1Cancelled, @"Process 1 should have been cancelled.");
	STAssertTrue(process2Cancelled, @"Process 2 should have been cancelled.");
}

- (void)testTwoProcessTwoCancel {

	__block BOOL process1Cancelled = NO;
	__block BOOL process2Cancelled = NO;

	DCTImageCacheMockCancel *process1 = [DCTImageCacheMockCancel new];
	process1.cancellationBlock = ^{
		process1Cancelled = YES;
	};

	DCTImageCacheMockCancel *process2 = [DCTImageCacheMockCancel new];
	process2.cancellationBlock = ^{
		process2Cancelled = YES;
	};

	_DCTImageCacheProcessManager *manager1 = [_DCTImageCacheProcessManager new];
	manager1.process = process1;

	_DCTImageCacheProcessManager *manager2 = [_DCTImageCacheProcessManager new];
	manager2.process = process2;

	_DCTImageCacheCancelProxy *proxy = [_DCTImageCacheCancelProxy new];
	[manager1 addCancelProxy:proxy];
	[manager2 addCancelProxy:proxy];

	_DCTImageCacheCancelProxy *proxy2 = [_DCTImageCacheCancelProxy new];
	[manager1 addCancelProxy:proxy2];
	[manager2 addCancelProxy:proxy2];

	STAssertFalse(process1Cancelled, @"Process 1 should not have been cancelled.");
	STAssertFalse(process2Cancelled, @"Process 2 should not have been cancelled.");

	[proxy cancel];

	STAssertFalse(process1Cancelled, @"Process 1 should not have been cancelled.");
	STAssertFalse(process2Cancelled, @"Process 2 should not have been cancelled.");

	[proxy2 cancel];

	STAssertTrue(process1Cancelled, @"Process 1 should have been cancelled.");
	STAssertTrue(process2Cancelled, @"Process 2 should have been cancelled.");
}

@end
