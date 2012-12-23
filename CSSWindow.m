#import "CSSWindow.h"
#import "AppDelegate.h"

@implementation CSSWindow

- (BOOL)preservesContentDuringLiveResize {
	return NO;
}

// TODO: use notifications instead
- (void)keyDown:(NSEvent *)theEvent {
	AppDelegate *css = (AppDelegate *)[[NSApplication sharedApplication] delegate];
	
	//NSLog(@"-- %d", [theEvent keyCode]);
	
	switch([theEvent keyCode]) {
		case 49: // space
			[css toggleSlideShow:self];
			break;
		case 53: // esc
			[css exitFullScreen:self];
			break;
		case 123: // left
			[css invalidateTimer];
			[imagesController selectPreviousImage];
			break;
		case 124: // right
			[css invalidateTimer];
			[imagesController selectNextImage];
			break;
		default:
			[super keyDown:theEvent];
	}
}

@end
