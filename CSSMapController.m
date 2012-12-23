//
//  MapController.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 14.11.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

#import "CSSMapController.h"
#import "CSSImageInfo.h"
#import "AppDelegate.h"
#import "NSImage+CSS.h"

NSString *const G_NORMAL_MAP = @"G_NORMAL_MAP";
NSString *const G_HYBRID_MAP = @"G_HYBRID_MAP";
NSString *const G_SATELLITE_MAP = @"G_SATELLITE_MAP";
NSString *const G_PHYSICAL_MAP = @"G_PHYSICAL_MAP";

static NSString *const kMapStyle = @"mapStyle";
static NSString *const kMapZoom = @"mapZoom";


@implementation CSSMapController

- (void)awakeFromNib {
	displayedImages = [[NSMutableSet alloc] init];
	
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"gmap" ofType:@"html"];	
	
	NSURL *url = [NSURL fileURLWithPath:filePath];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];

	// FIXME: webView frame should be set according to current window size, but it doesn't work..
	[webView setFrame:NSMakeRect(0.0, 0.0, 1500.0, 1000.0)];
		
	[webView setFrameLoadDelegate:self];
	[[webView mainFrame] loadRequest:request];
	
	scriptObject = [webView windowScriptObject];
	[scriptObject setValue:self forKey:@"mapController"];
}
/*
+ (NSString *)webScriptNameForSelector:(SEL)sel {
	if (sel == @selector(setMapType:))
		return @"setMapType";	
	return nil;
}
*/
- (void)mapTypeDidChange:(id)mapType {
	//NSLog(@"-- mapTypeDidChange:%@", mapType);
	
	if([[self mapStyles] containsObject:mapType]) {
		[[NSUserDefaults standardUserDefaults] setValue:mapType forKey:kMapStyle];
	}
}

- (void)zoomLevelDidChange:(id)zoomLevel {
	//NSLog(@"-- zoomLevelDidChange:%@", zoomLevel);

	[[NSUserDefaults standardUserDefaults] setValue:zoomLevel forKey:kMapZoom];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector { return NO; }
+ (BOOL)isKeyExcludedFromWebScript:(const char *)name { return NO; }


- (NSArray *)mapStyles {
	return [NSArray arrayWithObjects:G_PHYSICAL_MAP, G_NORMAL_MAP, G_SATELLITE_MAP, G_HYBRID_MAP, nil];
}

- (void)clearMap {
	[[webView mainFrame] loadRequest:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if(object == imagesController && [keyPath isEqualToString:@"selectedObjects"]) {
		[self evaluateNewJavaScriptOnSelectedObjectsChange];
	} else if(object == imagesController && [keyPath isEqualToString:@"arrangedObjects"]) {
		[self evaluateNewJavaScriptOnArrangedObjectsChange];
	}
}

- (void)evaluateNewJavaScriptOnSelectedObjectsChange {
	//NSLog(@"-- evaluateNewJavaScriptOnSelectedObjectsChange");

	NSMutableSet *toShow = [NSMutableSet setWithArray:[imagesController selectedObjects]];
	[toShow minusSet:displayedImages];
	NSMutableSet *toHide = [displayedImages mutableCopy];
	[toHide minusSet:[NSMutableSet setWithArray:[imagesController selectedObjects]]];
	
	NSMutableArray *jsCommands = [NSMutableArray array];

	for(CSSImageInfo *imageInfo in toHide) {
		NSString *jsHidePoint = [imageInfo jsHidePoint];
		if(!jsHidePoint) continue;
		[jsCommands addObject:jsHidePoint];
		[displayedImages removeObject:imageInfo];
	}

	for(CSSImageInfo *imageInfo in toShow) {
		NSString *jsShowPoint = [imageInfo jsShowPoint];
		if(!jsShowPoint) continue;
		[jsCommands addObject:jsShowPoint];
		[displayedImages addObject:imageInfo];
	}
	
	[toHide release];

	CSSImageInfo *lastObject = [[imagesController selectedObjects] lastObject];
	
	NSString *lat = [lastObject prettyLatitude];
	NSString *lon = [lastObject prettyLongitude];
	NSString *zoom = [[NSUserDefaults standardUserDefaults] valueForKey:kMapZoom];
	if([lat length] && [lon length] && zoom) {
		[jsCommands addObject:[NSString stringWithFormat:@"centerToLatitudeAndLongitudeWithZoom(%@, %@, %@);", lat, lon, zoom]];
	}
	
	NSString *js = [jsCommands componentsJoinedByString:@"\n"];
	//NSLog(@"-- \n%@", js);
	
	[webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)evaluateNewJavaScriptOnArrangedObjectsChange {
	//NSLog(@"-- evaluateNewJavaScriptOnArrangedObjectsChange");
	
	NSMutableSet *toAdd = [NSMutableSet setWithArray:[imagesController arrangedObjects]];
	[toAdd minusSet:displayedImages];
	NSMutableSet *toRemove = [displayedImages mutableCopy];
	[toRemove minusSet:[NSSet setWithArray:[imagesController arrangedObjects]]];
	
	NSMutableArray *jsCommands = [NSMutableArray array];

	for(CSSImageInfo *imageInfo in toRemove) {
		NSString *jsRemovePoint = [imageInfo jsRemovePoint];
		if(!jsRemovePoint) continue;
		[jsCommands addObject:jsRemovePoint];
		[displayedImages removeObject:imageInfo];
	}
	
	for(CSSImageInfo *imageInfo in toAdd) {
		NSString *jsAddPoint = [imageInfo jsAddPoint];
		if(!jsAddPoint) continue;
		[jsCommands addObject:jsAddPoint];
		//NSLog(@"  -- add %d", [imageInfo hash]);
	}
	
	[toRemove release];

	NSString *js = [jsCommands componentsJoinedByString:@"\n"];
	//NSLog(@"-- \n%@", js);
	
	[webView stringByEvaluatingJavaScriptFromString:js];
	
	[self evaluateNewJavaScriptOnSelectedObjectsChange];
}

#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	
	NSString *mapStyle = [[NSUserDefaults standardUserDefaults] stringForKey:kMapStyle];
	if(!mapStyle || ![[self mapStyles] containsObject:mapStyle]) {
		mapStyle = G_PHYSICAL_MAP;
		[[NSUserDefaults standardUserDefaults] setValue:mapStyle forKey:kMapStyle];
	}
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setMapStyle(%@);", mapStyle]];
}

- (void)dealloc {
	[displayedImages release];
	[super dealloc];
}

@end
