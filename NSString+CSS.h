//
//  NSString+CSS.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 26.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* const G_HYBRID_MAP;
extern NSString* const G_PHYSICAL_MAP;
extern NSString* const G_SATELLITE_MAP;
extern NSString* const G_NORMAL_MAP;

@interface NSString (CSS)

- (NSComparisonResult)numericCompare:(NSString *)aString;

@end
