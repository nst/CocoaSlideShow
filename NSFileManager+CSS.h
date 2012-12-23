//
//  NSFileManager+CSS.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 17.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSFileManager (CSS)

- (BOOL)isDirectory:(NSString *)path;
- (NSArray *)directoryContentFullPaths:(NSString*)dirPath recursive:(BOOL)isRecursive;
- (NSString *)prettyFileSize:(NSString *)path;

@end
