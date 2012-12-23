#import "CSSImageView.h"

@implementation CSSImageView

- (void)setDelegate:(id)del {
    delegate = del;
}

- (id) delegate {
    return (delegate);
}

- (void)mouseDown:(NSEvent *)theEvent {
	//NSLog(@"-- mouseDown: %@", self);
	
	NSArray *selectedObjects = [[NSApp delegate] valueForKeyPath:@"imagesController.selectedObjects"];
	if([selectedObjects count] != 1) return;
	
	NSString *path = [[selectedObjects lastObject] path];
	if(!path) return;

	NSPoint event_location = [theEvent locationInWindow];
	NSPoint p = [self convertPoint:event_location fromView:nil];
	
	isDraggingFromSelf = YES;
	[self dragFile:path fromRect:NSMakeRect(p.x, p.y, 0.0, 0.0) slideBack:YES event:theEvent];
	isDraggingFromSelf = NO;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if (!isDraggingFromSelf && [delegate respondsToSelector: @selector(draggingEntered:)]) {
		return [delegate draggingEntered:sender];
	}
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	if (!isDraggingFromSelf && [delegate respondsToSelector: @selector(prepareForDragOperation:)]) {
		return [delegate prepareForDragOperation:sender];
	}
	return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	if (!isDraggingFromSelf && [delegate respondsToSelector: @selector(performDragOperation:)]) {
		return [delegate performDragOperation:sender];
	}
	return NO;
}

@end
