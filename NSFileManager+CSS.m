//
//  NSFileManager+CSS.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 17.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager+CSS.h"


@implementation NSFileManager (CSS)

- (BOOL)isDirectory:(NSString *)path {
	BOOL isDir;
	[self fileExistsAtPath:path isDirectory:&isDir];
	return isDir;
}

- (NSArray *)directoryContentFullPaths:(NSString*)dirPath recursive:(BOOL)isRecursive {
	if(![self isDirectory:dirPath]) {
		return nil;
	}

	NSError *error = nil;
	NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:&error];
	if(dirContents == nil) {
		NSLog(@"-- cannot get contentsOfDirectoryAtPath:%@ error%@", dirPath, error);
		return nil;
	}
	
	NSMutableArray *fullPaths = [[NSMutableArray alloc] init];
	
	NSString *name;
	NSString *currentPath;
	for (name in dirContents) {
		currentPath = [dirPath stringByAppendingPathComponent:name];
		if([self isDirectory:currentPath]) {
			if(isRecursive) {
				[fullPaths arrayByAddingObjectsFromArray:[self directoryContentFullPaths:currentPath recursive:YES]];
			} else {
				continue;
			}
		}
		
		[fullPaths addObject:[dirPath stringByAppendingPathComponent:name]];
	}
	
	return [fullPaths autorelease];	
}

- (NSString *)prettyFileSize:(NSString *)path {
//	NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
	NSError *error = nil;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
	
	if(fileAttributes == nil) {
		NSLog(@"-- can't get attributesOfItemAtPath:%@ error:%@", path, error);
		return nil;
	}
									
	float fileSize = (float)[fileAttributes fileSize];
	NSString *unit = @"bytes";
	
	if(fileSize > 1024) {
		fileSize /= 1024;
		unit = @"KB";
	}
	
	if(fileSize > 1024) {
		fileSize /= 1024;
		unit = @"MB";
		return [NSString stringWithFormat:@"%0.1f %@", fileSize, unit];
	} else {
		return [NSString stringWithFormat:@"%d %@", (int)fileSize, unit];	
	}

}

@end
