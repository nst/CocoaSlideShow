//
//  NSImage+CSS.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 19.07.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

// http://www.cocoadev.com/index.pl?ThumbnailImages

#import "NSImage+CSS.h"
#import <Epeg/EpegWrapper.h>
#import <Quartz/Quartz.h>

@implementation NSImage (CSS)

static inline double rad(int alpha) {return ((alpha * pi)/180);}

+ (BOOL)scaleAndSaveJPEGThumbnailFromFile:(NSString *)srcPath toPath:(NSString *)dstPath boundingBox:(NSSize)boundingBox rotation:(int)orientationDegrees size:(NSSize *)mySize {
	NSImage *thumbnail = [[EpegWrapper imageWithPath2:srcPath boundingBox:boundingBox] rotatedWithAngle:orientationDegrees];
	NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData: [thumbnail TIFFRepresentation]];
	NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:0.75], NSImageCompressionFactor, [NSNumber numberWithBool:YES], NSImageProgressive, nil];
	NSData *data = [bitmap representationUsingType:NSJPEGFileType properties:properties];
	*mySize = [thumbnail size];
	return [data writeToFile:dstPath atomically:NO];
}

- (CIImage *)toCIImage {
    NSBitmapImageRep *bitmapimagerep = [[[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]] autorelease];
    CIImage *im = [[[CIImage alloc]
                    initWithBitmapImageRep:bitmapimagerep]
                   autorelease];
    return im;
}

- (BOOL)scaleAndSaveAsJPEGWithMaxWidth:(int)width 
                             maxHeight:(int)height 
                               quality:(float)quality
                           destination:(NSString *)dest {
	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSBitmapImageRep *rep = nil;
    NSBitmapImageRep *output = nil;
    NSImage *scratch = nil;
    int w,h,nw,nh;
    NSData *bitmapData;
    
    rep = [NSBitmapImageRep imageRepWithData:[self TIFFRepresentation]];
    
    // could not open file
    if (!rep) {
		NSLog(@"Could not create NSBitmapImageRep");
		[pool release];
		return NO;
    }
    
    // validation
    if (quality<=0.0) quality = 0.85;
    if (quality>1.0) quality = 1.00;
    
    // source image size
    w = nw = [rep pixelsWide];
    h = nh = [rep pixelsHigh];
    
    if (w>width || h>height) {
		float wr, hr;
		
		// ratios
		wr = w/(float)width;
		hr = h/(float)height;
		
		
		if (wr>hr) { // landscape
			nw = width;
			nh = h/wr;
		} else { // portrait
			nh = height;
			nw = w/hr;
		}
    }
    
    // image to render into
    scratch = [[[NSImage alloc] initWithSize:NSMakeSize(nw, nh)] autorelease];
    
    // could not create image
    if (!scratch) {
		NSLog(@"Could not render image");
		[pool release];
		return NO;
    }
    
    // draw into image, to scale it
    [scratch lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [rep drawInRect:NSMakeRect(0.0, 0.0, nw, nh)];
    output = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0,0,nw,nh)] autorelease];
    [scratch unlockFocus];
    
    // could not get result
    if (!output) {
		NSLog(@"Could not scale image");
		[pool release];
		return NO;
    }
    
    // save as JPEG
    NSDictionary *properties =
	[NSDictionary dictionaryWithObjectsAndKeys:
	 [NSNumber numberWithFloat:quality],
	 NSImageCompressionFactor, NULL];    
    
    bitmapData = [output representationUsingType:NSJPEGFileType
									  properties:properties];
    
    // could not get result
    if (!bitmapData) {
		NSLog(@"Could not convert to JPEG");
		[pool release];
		return NO;
    }
    
    BOOL ret = [bitmapData writeToFile:dest atomically:YES];
    
    [pool release];
    
    return ret;
}

// http://lists.apple.com/archives/Cocoa-dev/2005//Dec/msg00143.html
// TODO: use CIImage?
- (NSImage *)rotatedWithAngle:(int)alpha {
	float factorW, factorH, dW, dH;
	NSAffineTransform *centreOp, *rotateOp;
	NSImage *tmpImage;
	NSPoint startPoint;
	NSGraphicsContext* graphicsContext;
	BOOL wasAntialiasing;
	NSImageInterpolation previousImageInterpolation;
	
	if (0 == alpha) return self;
	factorW = fabs(cos(rad(alpha)));
	factorH = fabs(sin(rad(alpha)));
	dW = [self size].width * factorW + [self size].height * factorH;
	dH = [self size].width * factorH + [self size].height * factorW;
	tmpImage = [[NSImage alloc] initWithSize: NSMakeSize(dW, dH)];
	
	centreOp = [NSAffineTransform transform];
	[centreOp translateXBy: dW / 2 yBy: dH / 2];
	rotateOp = [NSAffineTransform transform];
	[rotateOp rotateByDegrees: alpha];
	[rotateOp appendTransform: centreOp];
	
	[self setMatchesOnMultipleResolution: NO];
	[self setUsesEPSOnResolutionMismatch: YES];
	[tmpImage lockFocus];
	graphicsContext = [NSGraphicsContext currentContext];
	wasAntialiasing = [graphicsContext shouldAntialias];
	previousImageInterpolation = [graphicsContext imageInterpolation];
	[graphicsContext setShouldAntialias: YES];
	[graphicsContext setImageInterpolation: NSImageInterpolationHigh];
	
	[rotateOp concat];
	startPoint = NSMakePoint(-[self size].width / 2, -[self size].height / 2);
	[self drawAtPoint: startPoint
			 fromRect: NSMakeRect(0, 0, [self size].width, [self size].height)
			operation: NSCompositeCopy
			 fraction: 1.0];
	
	[graphicsContext setShouldAntialias: wasAntialiasing];
	[graphicsContext setImageInterpolation: previousImageInterpolation];
	[tmpImage unlockFocus];
	[tmpImage setDataRetained: YES];
	[tmpImage setScalesWhenResized: YES];
	
	return [tmpImage autorelease];
}
/*
- (NSImage *)rotatedWithAngle:(int)alpha {
    CIImage *ciImage = [self toCIImage];
    
    CIImage *rotateImage = [ciImage rotateByDegrees:alpha];
    
    return [rotateImage toNSImage];
}
*/
@end
