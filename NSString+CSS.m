//
//  NSString+CSS.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 26.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSString+CSS.h"


@implementation NSString (CSS)

- (NSComparisonResult)numericCompare:(NSString *)aString {
	return [self compare:aString options:NSNumericSearch | NSCaseInsensitiveSearch];
}

- (NSString *)prettyMapStyle {
	if ([self isEqualToString:G_HYBRID_MAP]) return NSLocalizedString(@"Hybrid", @"");
	if ([self isEqualToString:G_NORMAL_MAP]) return NSLocalizedString(@"Street", @"");
	if ([self isEqualToString:G_PHYSICAL_MAP]) return NSLocalizedString(@"Physical", @"");
	if ([self isEqualToString:G_SATELLITE_MAP]) return NSLocalizedString(@"Satellite", @"");
	return @"Unknown";
}

@end
