/* MyImageView */

#import <Cocoa/Cocoa.h>

@interface CSSImageView : NSImageView
{
    IBOutlet id delegate;
	BOOL isDraggingFromSelf;
}

@end
