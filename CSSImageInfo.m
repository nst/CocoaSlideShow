//
//  CSSImageContainer.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 25.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSSImageInfo.h"
#import "NSString+CSS.h"
#import "AppDelegate.h"
#import "NSFileManager+CSS.h"
#import "NSImage+CSS.h"

static NSString *const kMultipleSelectionAllowsEdition = @"MultipleSelectionAllowsEdition";

static NSSet *keyPathsForValuesAffectingFlagIcon = nil;

@implementation CSSImageInfo

+ (NSSet *)keyPathsForValuesAffectingFlagIcon {
	if(keyPathsForValuesAffectingFlagIcon == nil) {
		keyPathsForValuesAffectingFlagIcon = [[NSSet setWithObject:@"isFlagged"] retain];
	}
	
	return keyPathsForValuesAffectingFlagIcon;
}
/*
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSMutableSet *set = [NSMutableSet set];

	if([key isEqualToString:@"flagIcon"]) {
		[set addObject:@"isFlagged"];
	}
			
	return set;
}
*/
//+ (void)initialize {
//    [self setKeys:[NSArray arrayWithObjects:@"isFlagged", nil] triggerChangeNotificationsForDependentKey:@"flagIcon"];
//}

- (void)setPath:(NSString *)aPath {

	if(aPath == nil) {
		NSLog(@"-- error: path is nil");
		return;
	}
	
	if(path != aPath) {
		[path release];
		path = [aPath retain];
	}
}

- (NSString *)path {
	return path;
}

- (id)initWithPath:(NSString *)aPath {
	self = [super init];
	[self setPath:aPath];
	return self;
}

+ (CSSImageInfo *)containerWithPath:(NSString *)aPath {
	return [[[CSSImageInfo alloc] initWithPath:aPath] autorelease];
}

- (void)dealloc {
	//NSLog(@"-- dealloc %@", path);

	if(source) {
		CFRelease(source);
		source = nil;
	}

	[path release];
	[metadata release];

	[super dealloc];
}

- (NSMutableDictionary *)metadata {
	if(!sourceWasRead) [self loadSource];
	return metadata;
}

- (NSString *)exifDateTime {
	NSDictionary *exif = [[self metadata] valueForKey:(NSString *)kCGImagePropertyExifDictionary];
	return [exif valueForKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
}

- (NSString *)prettyLatitude {
	NSDictionary *gps = [self gps];
	
	if(!gps) return @"";
	
	NSNumber *latitude = [gps valueForKey:@"Latitude"];
	NSString *latitudeRef = [gps valueForKey:@"LatitudeRef"];
	
	if(!latitude) return @"";
	
	return [latitudeRef isEqualToString:@"S"] ? [@"-" stringByAppendingFormat:@"%@", latitude] : [latitude description];
}

- (NSString *)prettyLongitude {
	NSDictionary *gps = [self gps];
	
	if(!gps) return @"";
	
	NSNumber *longitude = [gps valueForKey:@"Longitude"];
	if(!longitude) return @"";

	NSString *longitudeRef = [gps valueForKey:@"LongitudeRef"];
    
	return [longitudeRef isEqualToString:@"W"] ? [@"-" stringByAppendingFormat:@"%@", longitude] : [longitude description];
}

// FIXME: not thread safe, source might be read while export and released too early while displaying map, @synchronized seems to kill performance though
- (BOOL)loadSource {
	BOOL isMap = [[[NSApp delegate] valueForKey:@"isMap"] boolValue];
	BOOL isExporting = [[[NSApp delegate] valueForKey:@"isExporting"] boolValue];
	BOOL multipleImagesSelected = [[[NSApp delegate] valueForKeyPath:@"imagesController.multipleImagesSelected"] boolValue];
	BOOL readOnMultiSelect = [[NSUserDefaults standardUserDefaults] boolForKey:kMultipleSelectionAllowsEdition];

	if(!readOnMultiSelect && multipleImagesSelected && !isMap && !isExporting) {
		return NO;
    }
	
    if([self source] == NULL) return NO;
    
	// fill caches
	CFDictionaryRef metadataRef = CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
	if(metadataRef) {
		NSDictionary *immutableMetadata = (NSDictionary *)metadataRef;
		
		//NSLog(@"-- immutableMetadata %@", immutableMetadata);
		
		[metadata release];
		metadata = [immutableMetadata mutableCopy];
		CFRelease(metadataRef);
	}
    
	NSString *UTI = (NSString *)CGImageSourceGetType(source);

	CFRelease(source);
	source = nil;
	
	[self willChangeValueForKey:@"isJpeg"];
	isJpeg = [UTI isEqualToString:@"public.jpeg"];
	[self didChangeValueForKey:@"isJpeg"];
    
	return YES;
}

- (void)rotateLeft {
	userRotation -= 90;
}

- (void)rotateRight {
	userRotation += 90;	
}

//// http://www.impulseadventure.com/photo/exif-orientation.html
//- (int)orientationDegrees {
//	NSNumber *n = [[self metadata] valueForKey:@"Orientation"];
//	NSLog(@"-- n: %@", n);
//    
//    NSUInteger i = [n unsignedIntValue];
//    NSLog(@"------ %d", i);
//    
//    if(i == 1) return 0 + userRotation;
//    if(i == 8) return 90 + userRotation;
//    if(i == 3) return 180 + userRotation;
//    if(i == 6) return 270 + userRotation;
//
//    return userRotation;
//}

- (NSString *)fileName {
	return [path lastPathComponent];
}

- (void)setFileName:(NSString *)s {
	NSString *newPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:s];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:newPath]) return; // necessary?
	
	NSError *error = nil;	
	if([[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:&error]) {
		[self setValue:newPath forKey:@"path"];
	} else {
		NSLog(@"-- cannot move:%@ to:%@, error: %@", path, newPath, error);
	}
}

- (NSString *)latitude {
	return [[self gps] valueForKey:(NSString *)kCGImagePropertyGPSLatitude];
}

- (NSString *)longitude {
	return [[self gps] valueForKey:(NSString *)kCGImagePropertyGPSLongitude];
}

- (NSString *)latitudeRef {
	return [[self gps] valueForKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
}

- (NSString *)longitudeRef {
	return [[self gps] valueForKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
}

- (NSDictionary *)exif {
	return [[self metadata] valueForKey:(NSString *)kCGImagePropertyExifDictionary];
}

- (NSDictionary *)iptc {
	return [[self metadata] valueForKey:(NSString *)kCGImagePropertyIPTCDictionary];
}

- (NSDictionary *)gps {
	return [[self metadata] valueForKey:(NSString *)kCGImagePropertyGPSDictionary];
}

- (CGImageSourceRef)source {
    if(sourceWasRead) return source;
    
    if(source) return source;
    
    if(path == nil) return NULL;
    
    NSURL *url = [NSURL fileURLWithPath:path];
    if(url == nil) return NULL;
    
    source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    sourceWasRead = YES;
    if(source) return source;
    
	CGImageSourceStatus status = CGImageSourceGetStatus(source);
	NSLog(@"Error: could not create image source. Status: %d", status);
	return NULL;
}

- (BOOL)saveSourceWithMetadata {

	if([self source] == NULL) return NO;
	
	NSData *data = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)data, (CFStringRef)@"public.jpeg", 1, NULL);
    if(!destination) {
        NSLog(@"Error: could not create image destination");
		CFRelease(destination);
		if(source) {
			CFRelease(source);
			source = nil;
		}
        return NO;
    }
    
    CGImageDestinationAddImageFromSource(destination, source, 0, (CFDictionaryRef)metadata);
    BOOL success = CGImageDestinationFinalize(destination); // write metadata into the data object
	if(!success) {
		NSLog(@"Error: could not finalize destination");
		CFRelease(destination);
		if(source) {
			CFRelease(source);
			source = nil;
		}
		return NO;
	}
	
	CFRelease(destination);
	if(source) {
		CFRelease(source);
		source = nil;
	}
	
	NSURL *url = [NSURL fileURLWithPath:path];
	NSError *error = nil;
	success = [data writeToURL:url options:NSAtomicWrite error:&error];

	if(error) {
		NSLog(@"-- error: can't write data: %@", [error localizedDescription]);
	}
	
	return success;
}

- (BOOL)isJpeg {
	if(!sourceWasRead) [self loadSource];
	return isJpeg;
}

- (NSString *)jsAddPoint {
	NSString *latitude = [self prettyLatitude];
	NSString *longitude = [self prettyLongitude];
	if([latitude length] == 0 || [longitude length] == 0) return nil;

	NSString *filePath = [self path];
	NSString *fileName = [filePath lastPathComponent];
//	NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:YES];
	NSError *error = nil;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
	if(fileAttributes == nil) {
		NSLog(@"-- can't get attributesOfItemAtPath:%@ error:%@", filePath, error);
		return nil;
	}

	NSString *fileModDateString = fileAttributes ? [[fileAttributes valueForKey:NSFileModificationDate] description] : @"";
	
	return [NSString stringWithFormat:@"addPoint(\"h%d\", %@, %@, \"%@\", \"%@\", \"%@\", %d);", [self hash], latitude, longitude, fileName, filePath, fileModDateString, 0];
}

- (NSString *)jsRemovePoint {
	return [NSString stringWithFormat:@"removePoint(\"h%d\");", [self hash]];
}

- (NSString *)jsShowPoint {
	return [NSString stringWithFormat:@"showPoint(\"h%d\");", [self hash]];
}

- (NSString *)jsHidePoint {
	return [NSString stringWithFormat:@"hidePoint(\"h%d\");", [self hash]];
}

- (void)setUserComment:(NSString *)comment {
	if(![self isJpeg]) return;

	if(!sourceWasRead) [self loadSource];
	
	[self willChangeValueForKey:@"userComment"];
	[self willChangeValueForKey:@"exif"];
	NSMutableDictionary *exifData = [[metadata valueForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
	if(!exifData) {
		exifData = [[NSMutableDictionary alloc] init];
	}
	[exifData setObject:comment forKey:(NSString *)kCGImagePropertyExifUserComment];
	[metadata setObject:exifData forKey:(NSString *)kCGImagePropertyExifDictionary];
	[exifData release];
	[self didChangeValueForKey:@"exif"];
	[self didChangeValueForKey:@"userComment"];
	
	BOOL success = [self saveSourceWithMetadata];
	if(!success) {
		NSLog(@"Error: can't set user comment");
	}
	
	return;
}

- (void)setKeywords:(NSArray *)keywords {
	if(![self isJpeg]) return;

	if(!sourceWasRead) [self loadSource];

	[self willChangeValueForKey:@"keywords"];
	NSMutableDictionary *iptcDict = [[self iptc] mutableCopy];
	if(!iptcDict) {
		iptcDict = [[NSMutableDictionary alloc] init];
	}
	[iptcDict setObject:keywords forKey:(NSString *)kCGImagePropertyIPTCKeywords];
	[metadata setObject:iptcDict forKey:(NSString *)kCGImagePropertyIPTCDictionary];
	[iptcDict release];
	[self didChangeValueForKey:@"keywords"];
	
	BOOL success = [self saveSourceWithMetadata];
	if(!success) {
		NSLog(@"Error: can't set keywords");
	}
}

- (NSArray *)keywords {
	return [[self iptc] valueForKey:(NSString *)kCGImagePropertyIPTCKeywords];
}

- (NSString *)userComment {
	return [[self exif] valueForKey:(NSString *)kCGImagePropertyExifUserComment];
}

- (NSString *)prettyGPS {
	NSDictionary *gps = [self gps];
	if(!gps) return nil;
	
	NSString *latitude = [[gps valueForKey:(NSString *)kCGImagePropertyGPSLatitude] description];
	NSString *longitude = [[gps valueForKey:(NSString *)kCGImagePropertyGPSLongitude] description];
	NSString *latitudeRef = [gps valueForKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
	NSString *longitudeRef = [gps valueForKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
	
	if(!latitude || !longitude || !latitudeRef || !longitudeRef) return nil;
	
	NSString *trimedLatitude = [latitude length] > 8 ? [latitude substringToIndex:8] : latitude;
	NSString *trimedLongitude = [longitude length] > 8 ? [longitude substringToIndex:8] : longitude;
	
	return [NSString stringWithFormat:@"%@ %@, %@ %@", trimedLatitude, latitudeRef, trimedLongitude, longitudeRef];
}

- (NSImage *)image {
    //int orientationDegrees = [self orientationDegrees];
	return [[[[NSImage alloc] initByReferencingFile:path] autorelease] rotatedWithAngle:0];
}

// just to appear to be KVC compliant, useful when droping an image on the imageView
- (void)setImage:(NSImage *)anImage {
	//NSLog(@"-- setImage:%@", anImage);
}

- (NSURL *)googleMapsURL {
	NSString *latitude = [self prettyLatitude];
	NSString *longitude = [self prettyLongitude];
	
	if([latitude length] == 0 || [longitude length] == 0) return nil;
	
	NSString *s = [NSString stringWithFormat:@"http://maps.google.com/?q=%@,%@", latitude, longitude];
	return [NSURL URLWithString:s];
}

- (NSString *)prettyImageSize {
	NSString *x = [[self exif] valueForKey:(NSString *)kCGImagePropertyExifPixelXDimension];
	NSString *y = [[self exif] valueForKey:(NSString *)kCGImagePropertyExifPixelYDimension];
	if(x && y) {
		return [NSString stringWithFormat:@"%@x%@", x, y];
	}
	return nil;
}

- (NSString *)prettyFileSize {
	return [[NSFileManager defaultManager] prettyFileSize:path];	
}

- (void)flag {
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isFlagged"];
}

- (void)unflag {
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isFlagged"];
}

- (void)toggleFlag {
	[self setValue:[NSNumber numberWithBool:!isFlagged] forKey:@"isFlagged"];
}

- (void)removeFlag {
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isFlagged"];	
}

- (BOOL)isFlagged {
	return isFlagged;
}

- (NSImage *)flagIcon {
	return isFlagged ? [NSImage imageNamed:@"Flagged.png"] : nil;
}

- (void)copyToDirectory:(NSString *)destDirectory {
	NSString *destPath = [destDirectory stringByAppendingPathComponent:[path lastPathComponent]];
	NSFileManager *fm = [NSFileManager defaultManager];

	if ([fm fileExistsAtPath:path]) {
		NSError *error = nil;
		BOOL success = [fm copyItemAtPath:path toPath:destPath error:&error];
		if(success == NO) {
			NSLog(@"-- cannot copyItemAtPath:%@ toPath:%@ error:%@", path, destPath, error);
		}
	}
}

- (void)moveToTrash {
	NSString *trashPath = [[@"~/.Trash/" stringByExpandingTildeInPath] stringByAppendingPathComponent:[path lastPathComponent]];
	NSError *error = nil;
	BOOL success = [[NSFileManager defaultManager] moveItemAtPath:path toPath:trashPath error:&error];
	if(success == NO) {
		NSLog(@"-- cannot move:%@ to:%@, error: %@", path, trashPath, error);
	}
}

- (void)revealInFinder {
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
}

@end
