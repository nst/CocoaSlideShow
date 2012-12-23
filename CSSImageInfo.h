//
//  CSSImageContainer.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 25.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CSSImageInfo : NSObject {
	NSString *path;
	CGImageSourceRef source;
	NSMutableDictionary *metadata;

	BOOL sourceWasRead;
	BOOL isFlagged;
	BOOL isLoadingCache;
	BOOL isJpeg;
	
	int userRotation;
}

- (CGImageSourceRef)source;

+ (CSSImageInfo *)containerWithPath:(NSString *)aPath;

- (NSString *)jsAddPoint;
- (NSString *)jsRemovePoint;

- (NSString *)jsShowPoint;
- (NSString *)jsHidePoint;

- (NSString *)exifDateTime;

- (NSString *)prettyLatitude;
- (NSString *)prettyLongitude;

- (BOOL)loadSource;
- (BOOL)isJpeg;

- (NSImage *)image;

- (void)rotateLeft;
- (void)rotateRight;

//- (int)orientationDegrees;

- (NSString *)path;
- (NSImage *)image;

- (NSDictionary *)exif;
- (NSDictionary *)gps;

- (NSString *)path;

- (NSURL *)googleMapsURL;

- (NSString *)fileName;
- (void)setFileName:(NSString *)s;

- (void)flag;
- (void)unflag;
- (void)toggleFlag;
- (void)removeFlag;
- (BOOL)isFlagged;
- (NSImage *)flagIcon;

@end
