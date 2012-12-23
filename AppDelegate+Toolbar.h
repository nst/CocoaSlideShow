//
//  CocoaSlideShow+Toolbar.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 04.05.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@interface AppDelegate (Toolbar)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;

@end
