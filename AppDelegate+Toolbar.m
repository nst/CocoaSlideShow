//
//  CocoaSlideShow+Toolbar.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 04.05.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

#import "AppDelegate+Toolbar.h"

#define kAlwaysSelected 0
#define kSelectedIfAtLeastOneImageSelected 1
#define kSelectedIfAtLeastOneGPSImageSelected 2
#define kSelectedIfGPSOrCanGoBackToImage 3

@implementation AppDelegate (Toolbar)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	if ([itemIdentifier isEqualToString:@"setDirectory"]) {
        [item setLabel:NSLocalizedString(@"Set Directory…", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Set Directory…", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Set Directory…", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"folder.png"]];
		[item setTag:kAlwaysSelected];
        [item setTarget:self];
        [item setAction:@selector(setDirectory:)];
	} else if ([itemIdentifier isEqualToString:@"addFiles"]) {
        [item setLabel:NSLocalizedString(@"Add Files…", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Add Files…", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Add Files…", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"add.png"]];
		[item setTag:kAlwaysSelected];
        [item setTarget:self];
        [item setAction:@selector(addDirectory:)];
	} else if ([itemIdentifier isEqualToString:@"flag"]) {
        [item setLabel:NSLocalizedString(@"Flag", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Flag", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Flag", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"flag.png"]];
		[item setTag:kSelectedIfAtLeastOneImageSelected];
        [item setTarget:self];
        [item setAction:@selector(toggleFlags:)];
	} else if ([itemIdentifier isEqualToString:@"fullScreen"]) {
        [item setLabel:NSLocalizedString(@"Full Screen", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Full Screen", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Full Screen", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"fullscreen.png"]];
		[item setTag:kAlwaysSelected];
        [item setTarget:self];
		[item setAction:@selector(fullScreenMode:)];
	} else if ([itemIdentifier isEqualToString:@"slideShow"]) {
        [item setLabel:NSLocalizedString(@"Slideshow", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Slideshow", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Slideshow", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"slideshow.png"]];
		[item setTag:kAlwaysSelected];
        [item setTarget:self];
		[item setAction:@selector(startSlideShow:)];
	} else if ([itemIdentifier isEqualToString:@"rotateLeft"]) {
        [item setLabel:NSLocalizedString(@"Rotate Left", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Rotate Left", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Rotate Left", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"left.png"]];
		[item setTag:kSelectedIfAtLeastOneImageSelected];
        [item setTarget:self];
		[item setAction:@selector(rotateLeft:)];
	} else if ([itemIdentifier isEqualToString:@"rotateRight"]) {
        [item setLabel:NSLocalizedString(@"Rotate Right", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Rotate Right", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Rotate Right", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"right.png"]];
		[item setTag:kSelectedIfAtLeastOneImageSelected];
        [item setTarget:self];
		[item setAction:@selector(rotateRight:)];
	} else if ([itemIdentifier isEqualToString:@"remove"]) {
        [item setLabel:NSLocalizedString(@"Remove", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Remove", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Remove", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"remove.png"]];
		[item setTag:kSelectedIfAtLeastOneImageSelected];
        [item setTarget:self];
		[item setAction:@selector(remove:)];
	} else if ([itemIdentifier isEqualToString:@"trash"]) {
        [item setLabel:NSLocalizedString(@"Move to Trash", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Trash", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Trash", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"trash.png"]];
		[item setTag:kSelectedIfAtLeastOneImageSelected];
        [item setTarget:self];
		[item setAction:@selector(moveToTrash:)];
	} else if ([itemIdentifier isEqualToString:@"gmap"]) {
        [item setLabel:NSLocalizedString(@"Google Map", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Google Map", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Google Map", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"gmap.png"]];
		[item setTag:kSelectedIfGPSOrCanGoBackToImage];
        [item setTarget:self];
		[item setAction:@selector(toggleGoogleMap:)];	
    }	
    return [item autorelease];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:@"setDirectory", @"addFiles",
			NSToolbarSeparatorItemIdentifier, @"flag", @"fullScreen", @"slideShow", @"gmap", @"rotateLeft", @"rotateRight", @"remove",
			NSToolbarFlexibleSpaceItemIdentifier, @"trash", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    NSArray *standardItems = [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
							  NSToolbarSpaceItemIdentifier,
							  NSToolbarFlexibleSpaceItemIdentifier,
							  NSToolbarCustomizeToolbarItemIdentifier, nil];
	NSArray *moreItems = [NSArray array];
	return [[[self toolbarDefaultItemIdentifiers:nil] arrayByAddingObjectsFromArray:standardItems] arrayByAddingObjectsFromArray:moreItems];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	//NSLog(@"-- %@", [theItem label]);
	if([theItem tag] == kAlwaysSelected) {
		return YES;
	} else if ([theItem tag] == kSelectedIfAtLeastOneImageSelected) {
		return [[imagesController selectedObjects] count];
	} else if ([theItem tag] == kSelectedIfAtLeastOneGPSImageSelected) {
		return [imagesController atLeastOneImageWithGPSSelected];
	} else if ([theItem tag] == kSelectedIfGPSOrCanGoBackToImage) {
		return [[NSApp delegate] isMap] || [imagesController atLeastOneImageWithGPSSelected];
	}
	return NO;
}

- (void)toggleFlags:(id)sender {
	[imagesController toggleFlags:sender];
}

- (void)remove:(id)sender {
	[imagesController remove:sender];
}

- (void)moveToTrash:(id)sender {
	[imagesController moveToTrash:sender];
}

- (void)openGoogleMap:(id)sender {
	[imagesController openGoogleMap:sender];
}

@end