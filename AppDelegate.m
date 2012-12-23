#import "AppDelegate.h"
#import "AppleRemote.h"
#import "NSFileManager+CSS.h"
#import <Sparkle/SUUpdater.h>
#import "CSSBorderlessWindow.h"
#import <Carbon/Carbon.h>
#import "NSImage+CSS.h"
#import "CSSImageInfo.h"

static NSString *const kImagesDirectory = @"ImagesDirectory";
static NSString *const kKMLThumbnailsRemoteURLs = @"KMLThumbnailsRemoteURLs";
static NSString *const kRemoteKMLThumbnails = @"RemoteKMLThumbnails";
static NSString *const kSlideShowSpeed = @"SlideShowSpeed";
static NSString *const kThumbsExportSizeTag = @"ThumbsExportSizeTag";
static NSString *const kThumbsExportSizeHeight = @"ThumbsExportSizeHeight";
static NSString *const kThumbsExportSizeWidth = @"ThumbsExportSizeWidth";
static NSString *const kSlideshowIsFullscreen = @"SlideshowIsFullscreen";

@implementation AppDelegate

- (id)init {
	self = [super init];
	
	images = [[NSMutableArray alloc] init];
	isFullScreen = NO;
	takeFilesFromDefault = YES;
		
	undoManager = [[NSUndoManager alloc] init];
	[undoManager setLevelsOfUndo:20];

	return self;
}

- (ImagesController *)imagesController {
	return imagesController;
}

- (void)dealloc {
	[mainWindow release];
	[imagesController release];
	[images release];
	[remoteControl autorelease];
	[undoManager release];

	[super dealloc];
}

- (void)playSuccessSound {
	NSString *soundPath = @"/System/Library/Sounds/Hero.aiff";
	if([[NSFileManager defaultManager] fileExistsAtPath:soundPath]) {
		NSSound *sound = [[NSSound alloc] initWithContentsOfFile:soundPath byReference:YES];
		[sound play];
		[sound release];
	}
}

- (NSUndoManager *)undoManager {
	return undoManager;
}

- (BOOL)isMap {
	return [tabView selectedTabViewItem] == mapTabViewItem;
}

- (void)setupImagesControllerWithDir:(NSString *)dir recursive:(BOOL)isRecursive {
	[images removeAllObjects];

	NSArray *dirContent = [[NSFileManager defaultManager] directoryContentFullPaths:dir recursive:isRecursive];
	
	dirContent = [dirContent sortedArrayUsingSelector:@selector(numericCompare:)];
	
	[imagesController addFiles:dirContent];
	if([dirContent count] > 0) [imagesController setSelectionIndex:0];
}

- (void)setupToolbar {	
    toolbar = [[[NSToolbar alloc] initWithIdentifier:@"mainToolbar"] autorelease];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [mainWindow setToolbar:toolbar];
}

- (void)awakeFromNib {
    
	remoteControl = [[AppleRemote alloc] initWithDelegate: self];
	
	[mainWindow registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	
	[self setupToolbar];
	
	[[userCommentTextField cell] setSendsActionOnEndEditing:YES];
	[[keywordsTokenField cell] setSendsActionOnEndEditing:YES];
	
	[imagesController setAutomaticallyPreparesContent:YES];
	
	NSTableColumn *flagColumn = [tableView tableColumnWithIdentifier:@"flag"];
	NSImage *flagHeaderImage = [NSImage imageNamed:@"FlaggedHeader.png"];
	NSImageCell *flagHeaderImageCell = [flagColumn headerCell];
	[flagHeaderImageCell setImage:flagHeaderImage];
	[flagColumn setHeaderCell:flagHeaderImageCell];
	
	[tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
	[tableView setDraggingSourceOperationMask:NSDragOperationNone forLocal:YES];
	
	[mainWindow setDelegate:self];
	
	[progressIndicator setHidden:YES];

	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:1], @"SlideShowSpeed",
	    [NSNumber numberWithBool:YES], @"SlideshowIsFullscreen", nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	
	[panelImageView setImageScaling:NSImageScaleProportionallyUpOrDown];
	
	[imagesController addObserver:self forKeyPath:@"arrangedObjects.isFlagged" options:NSKeyValueChangeSetting context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if(object == imagesController && [keyPath isEqualToString:@"arrangedObjects.isFlagged"]) {
		NSUInteger objectsCount = [[imagesController arrangedObjects] count];
		NSUInteger flaggedCount = [[imagesController flaggedIndexes] count];
		
		// TODO: localize
		NSString *title = [NSString stringWithFormat:@"%d images (%d flags)", objectsCount, flaggedCount];
		
		[[[tableView tableColumnWithIdentifier:@"name"] headerCell] setTitle:title];
		[tableView reloadData];
	}	
}

- (NSString *)chooseDirectory {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseFiles:NO];
    [oPanel setCanChooseDirectories:YES];

    int result = [oPanel runModalForDirectory:nil
                                         file:nil
                                        types:nil];
    NSString *dir = nil;
	
	if (result == NSOKButton) {
		dir = [[oPanel filenames] lastObject];
    }
	
	return dir;
}

- (IBAction)open:(id)sender {
	NSString *dir = [self chooseDirectory];
	if(dir) {
		[self setupImagesControllerWithDir:dir recursive:YES];
	}
}

- (IBAction)setDirectory:(id)sender {
	NSString *dir = [self chooseDirectory];
	if(dir) {
		[self setupImagesControllerWithDir:dir recursive:YES];
		[[NSUserDefaults standardUserDefaults] setValue:dir forKey:kImagesDirectory];
	}
}

- (IBAction)addDirectory:(id)sender {
	NSString *dir = [self chooseDirectory];
	if(dir) {
		[imagesController addDirFiles:dir];
	}
}

- (IBAction)exportToDirectory:(id)sender {
	NSString *destDirectory = [self chooseDirectory];
	if(!destDirectory) {
		return;
	}

	[[imagesController selectedObjects] makeObjectsPerformSelector:@selector(copyToDirectory:) withObject:destDirectory];
	[self playSuccessSound];
}

- (BOOL)isFullScreen {
	return isFullScreen;
}

- (void)rotate:(NSImageView *)iv clockwise:(BOOL)cw {
	[iv setImage:[[iv image] rotatedWithAngle: cw ? -90 : 90]];
	
	SEL selector = cw ? @selector(rotateLeft) : @selector(rotateRight);
	[[imagesController selectedObjects] makeObjectsPerformSelector:selector];
}

- (IBAction)rotateLeft:(id)sender {
	NSImageView *iv = isFullScreen ? panelImageView : imageView;
	[self rotate:iv clockwise:NO];
}

- (IBAction)rotateRight:(id)sender {
	NSImageView *iv = isFullScreen ? panelImageView : imageView;
	[self rotate:iv clockwise:YES];
}

- (IBAction)fullScreenMode:(id)sender {
	
	if(isFullScreen) return;

	[NSCursor setHiddenUntilMouseMoves:YES];

	SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
		
	NSScreen *screen = [mainWindow screen];

	[slideShowPanel setContentSize:[screen frame].size];
    [slideShowPanel setFrame:[screen frame] display:YES];

	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isFullScreen"];
}

- (IBAction)undo:(id)sender {
	[undoManager undo];
}

- (IBAction)redo:(id)sender {
	[undoManager redo];
}

- (void)invalidateTimer {
	if([timer isValid]) {
		[timer invalidate];
		timer = nil;
	}	
}

- (IBAction)exitFullScreen:(id)sender {

	if(!isFullScreen) return;
	
	SetSystemUIMode(kUIModeNormal, 0);
	
	[self invalidateTimer];

	[NSCursor unhide];
	
	[slideShowPanel orderOut:self];

	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isFullScreen"];
}

- (IBAction)toggleFullScreen:(id)sender {
	if(isFullScreen) {
		[self exitFullScreen:nil];
	} else {
		[self fullScreenMode:nil];	
	}
}

- (void)timerNextTick {
	if(![imagesController canSelectNext]) {
		[self invalidateTimer];
        if(isFullScreen) [self exitFullScreen:nil];
	}
	[imagesController selectNextImage]; 
}

- (IBAction)toggleSlideShow:(id)sender {
	if([timer isValid]) {
		[self invalidateTimer];
	} else {
		timer = [NSTimer scheduledTimerWithTimeInterval:[[[NSUserDefaults standardUserDefaults] valueForKey:kSlideShowSpeed] floatValue]
												  target:self
												selector:@selector(timerNextTick)
												userInfo:NULL
												repeats:YES];
	}
}

- (IBAction)startSlideShow:(id)sender {
	if([[NSUserDefaults standardUserDefaults] boolForKey:kSlideshowIsFullscreen]) {
		[self fullScreenMode:self];
	}
	[self toggleSlideShow:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self exitFullScreen:self];
}

- (void)hideGoogleMap {
	[tabView selectTabViewItem:imageTabViewItem];
	[imagesController removeObserver:mapController forKeyPath:@"selectedObjects"];
	[imagesController removeObserver:mapController forKeyPath:@"arrangedObjects"];
	[mapController clearMap];
}

- (void)showGoogleMap {
	[tabView selectTabViewItem:mapTabViewItem];
	[imagesController addObserver:mapController forKeyPath:@"selectedObjects" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:NULL];
	[imagesController addObserver:mapController forKeyPath:@"arrangedObjects" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:NULL];
	[mapController evaluateNewJavaScriptOnArrangedObjectsChange];
}

- (IBAction)toggleGoogleMap:(id)sender {
	if([tabView selectedTabViewItem] == mapTabViewItem) {
		[self hideGoogleMap];
	} else {
		[self showGoogleMap];
	}
}

- (void)sendRemoteButtonEvent: (RemoteControlEventIdentifier) event pressedDown: (BOOL) pressedDown remoteControl: (RemoteControl*) remoteControl {
	//NSLog(@"Button %d pressed down %d", event, pressedDown);
	
	NSString* buttonName = nil;
	NSString* pressed = @"";
	
	if(!pressedDown) {
		return;
	}
	
	switch(event) {
		case kRemoteButtonPlus:
			buttonName = @"Volume up";
			[self rotateRight:self];
			
			if (pressedDown) pressed = @"(down)"; else pressed = @"(up)";			
			break;
		case kRemoteButtonMinus:
			buttonName = @"Volume down";
			[self rotateLeft:self];
			
			if (pressedDown) pressed = @"(down)"; else pressed = @"(up)";
			break;			
		case kRemoteButtonMenu:
			buttonName = @"Menu";
			if(isFullScreen) {
				[self exitFullScreen:self];
			} else {
				[self fullScreenMode:self];
			}
			break;			
		case kRemoteButtonPlay:
			buttonName = @"Play";
			
			if(isFullScreen) {
				[self toggleSlideShow:self];
			} else {
				[self startSlideShow:self];
			}
			
			break;			
		case kRemoteButtonRight:	
			buttonName = @"Right";
			[imagesController selectNextImage];
			break;			
		case kRemoteButtonLeft:
			buttonName = @"Left";
			[imagesController selectPreviousImage];
			break;			
		case kRemoteButtonRight_Hold:
			buttonName = @"Right holding";	
			if (pressedDown) pressed = @"(down)"; else pressed = @"(up)";
			break;	
		case kRemoteButtonLeft_Hold:
			buttonName = @"Left holding";		
			if (pressedDown) pressed = @"(down)"; else pressed = @"(up)";
			break;			
		case kRemoteButtonPlay_Hold:
			buttonName = @"Play (sleep mode)";
			break;			
		case kRemoteButtonMenu_Hold:
			buttonName = @"Menu (long)";
			break;
		case kRemoteControl_Switched:
			buttonName = @"Remote Control Switched";
			break;
		default:
			//NSLog(@"Unmapped event for button %d", event); 
			break;
	}
	
	//NSLog(@"buttonName %@", buttonName);
}

#pragma mark NSApplication Delegates

- (void)applicationWillBecomeActive:(NSNotification *)aNotification {
    [remoteControl startListening: self];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
    [remoteControl stopListening: self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	if(takeFilesFromDefault) {
		NSString *defaultDir = [NSString pathWithComponents:[NSArray arrayWithObjects:NSHomeDirectory(), @"Pictures", nil]];
		NSString *defaultValue = [[NSUserDefaults standardUserDefaults] valueForKey:kImagesDirectory];
		if(defaultValue) {
			defaultDir = defaultValue;
		}
		[self setupImagesControllerWithDir:defaultDir recursive:NO];
	}
	
	NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"]];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	
    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	if([filenames count] > 0) {
		int numberOfImagesBefore = [[imagesController arrangedObjects] count];
		[imagesController addFiles:filenames];
		int numberOfImagesAfter = [[imagesController arrangedObjects] count];
		if(numberOfImagesAfter > numberOfImagesBefore) {
			[imagesController setSelectionIndex:numberOfImagesBefore];
		}
		takeFilesFromDefault = NO;
	}
}

#pragma mark NSWindow delegates

- (void)windowWillClose:(NSNotification *)aNotification {
	[NSApp terminate:self];
}

#pragma mark NSDraggingSource

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	NSArray *files = [[[imagesController arrangedObjects] objectsAtIndexes:rowIndexes] valueForKey:@"path"];
    [pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
    [pboard setPropertyList:files forType:NSFilenamesPboardType];
    return YES;
}

#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	//NSLog(@"%s", __FUNCTION__);
	return NSDragOperationLink;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	//NSLog(@"%s", __FUNCTION__);
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	//NSLog(@"%s", __FUNCTION__);
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
 
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];

		int numberOfImagesBefore = [[imagesController arrangedObjects] count];

		//NSLog(@"CocoaSlidesShow.m | performDragOperation | add files: %@", files);
		[imagesController addFiles:files];
		
		int numberOfImagesAfter = [[imagesController arrangedObjects] count];
		if(numberOfImagesAfter > numberOfImagesBefore) {
			[imagesController setSelectionIndex:numberOfImagesBefore];
		}
    }
    return YES;
}

- (IBAction)revealInFinder:(id)sender {
	[[imagesController selectedObjects] makeObjectsPerformSelector:@selector(revealInFinder)];
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	isSaving = YES;
	return YES;
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
	isSaving = NO;
}

#pragma mark NSTableView delegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {	
	if([tabView selectedTabViewItem] == mapTabViewItem && [[imagesController selectedObjects] count] == 0) {
		[self hideGoogleMap];
	}
}

- (void)prepareProgressIndicator:(unsigned int)count {
	[progressIndicator setHidden:NO];
	[progressIndicator setMinValue:(double)0.0];
	[progressIndicator setMaxValue:(double)count];
	[progressIndicator setDoubleValue:0.0];
}

- (void)exportFinished {
	[self playSuccessSound];
	
	[progressIndicator setDoubleValue:1.0];
	[progressIndicator setHidden:YES];
	[progressIndicator setDoubleValue:0.0];
	
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isExporting"];
}

#pragma mark KML export

- (void)incrementExportProgress {
	double newValue = [progressIndicator doubleValue] + 1;
	[progressIndicator setDoubleValue:newValue];
}

#pragma KML File Export

- (NSString *)chooseKMLExportDirectory {
    NSSavePanel *sPanel = [NSSavePanel savePanel];
	
	[sPanel setAccessoryView:kmlSavePanelAccessoryView];
	[sPanel setCanCreateDirectories:YES];
	
	NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];

	int runResult = [sPanel runModalForDirectory:desktopPath file:@"KMLExport"];
	
	return (runResult == NSOKButton) ? [sPanel filename] : nil;
}

- (IBAction)exportKMLToFile:(id)sender {
	if(isExporting) return;

	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isExporting"];
	
	NSString *dir = [self chooseKMLExportDirectory];
	if(!dir) return;

	BOOL addThumbnails = [[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeThumbsInKMLExport"];

	NSError *error = nil;
	BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error];
	if(!success) {
		NSLog(@"Error: can't create dir at path %@, error:%@", dir, error);
		//return;
	}
	
	NSString *kmlFilePath = [dir stringByAppendingPathComponent:@"CocoaSlideShow.kml"];

    NSString *thumbsDir = nil;
    
	if(addThumbnails) {
		thumbsDir = [dir stringByAppendingPathComponent:@"images"];

		error = nil;
		success = [[NSFileManager defaultManager] createDirectoryAtPath:thumbsDir withIntermediateDirectories:YES attributes:nil error:&error];
		if(!success) {
			NSLog(@"Error: can't create dir at path %@, error:%@", dir, error);
			//return;
		}
	}
	
	NSArray *kmlImages = [[[imagesController selectedObjects] copy] autorelease];
		
	if(addThumbnails) {
		[self prepareProgressIndicator:[kmlImages count]];
	}
	    
	if(addThumbnails) thumbsDir = [[kmlFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"images"];
	
	NSString *XMLContainer = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> <kml xmlns=\"http://www.opengis.net/kml/2.2\">\n<Folder>\n%@</Folder>\n</kml>\n";
	
	BOOL useRemoteBaseURL = [[NSUserDefaults standardUserDefaults] boolForKey:kRemoteKMLThumbnails];
	NSString *baseURL = @"images/";
	if(useRemoteBaseURL) {
		baseURL = [[NSUserDefaults standardUserDefaults] valueForKey:kKMLThumbnailsRemoteURLs];
		if(![baseURL hasSuffix:@"/"]) {
			baseURL = [baseURL stringByAppendingString:@"/"];
		}
	}
    
    NSMutableArray *placemarkStrings = [NSMutableArray array];
    
    NSOperationQueue *exportQueue = [[[NSOperationQueue alloc] init] autorelease];

    NSBlockOperation *exportOperationBlock = [[[NSBlockOperation alloc] init] autorelease];
            
	for(CSSImageInfo *cssImageInfo in kmlImages) {
        
        [exportOperationBlock addExecutionBlock:^{
        
            NSString *latitude = [cssImageInfo prettyLatitude];
            NSString *longitude = [cssImageInfo prettyLongitude];
            NSString *timestamp = [cssImageInfo exifDateTime];
            
            NSString *imageName = [[[cssImageInfo path] lastPathComponent] lowercaseString];
            
            if([latitude length] == 0 || [longitude length] == 0) {
                return;
            }

            NSMutableString *placemarkString = [NSMutableString stringWithFormat:@"    <Placemark><name>%@</name><timestamp><when>%@</when></timestamp><Point><coordinates>%@,%@</coordinates></Point>", imageName, timestamp, longitude, latitude];
            
            if(addThumbnails) {
                
                [self incrementExportProgress];
                
                NSString *thumbPath = [[thumbsDir stringByAppendingPathComponent:[[cssImageInfo path] lastPathComponent]] lowercaseString];

                float w1, h1, w2, h2;

                if ([[cssImageInfo image] size].height > [[cssImageInfo image] size].width) {
                    w1 = 106.0;
                    h1 = 160.0;
                    w2 = 360.0;
                    h2 = 510.0;
                } else {
                    w1 = 160.0;
                    h1 = 106.0;
                    w2 = 510.0;
                    h2 = 360.0;
                }
                
                NSSize size = NSZeroSize;
                BOOL success = useRemoteBaseURL ? [NSImage scaleAndSaveJPEGThumbnailFromFile:[cssImageInfo path] toPath:thumbPath boundingBox:NSMakeSize(w1, h1) rotation:0 size:&size] :
                [NSImage scaleAndSaveJPEGThumbnailFromFile:[cssImageInfo path] toPath:thumbPath boundingBox:NSMakeSize(w2, h2) rotation:0 size:&size];			
                
                if(success == NO) {
                    NSLog(@"Could not scale and save as jpeg into %@", thumbPath);
                }
                
                NSString *imageName = [[[cssImageInfo path] lastPathComponent] lowercaseString];
                
                [placemarkString appendFormat:@"<description>&lt;img src=\"%@%@\" height=\"%.0f\" width=\"%.0f\" /&gt;</description><Style><text>$[description]</text></Style> ", baseURL, imageName, (float)size.height, (float)size.width];
            }

            [placemarkString appendString:@"</Placemark>\n"];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                [placemarkStrings addObject:placemarkString];
            }];
        }];
        
        [exportOperationBlock setCompletionBlock:^{
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                NSString *placemarkString = [placemarkStrings componentsJoinedByString:@""];
                
                NSString *kml = [NSString stringWithFormat:XMLContainer, placemarkString];
                                
                NSError *anError = nil;
                [kml writeToFile:kmlFilePath atomically:YES encoding:NSUTF8StringEncoding error:&anError];
                
                if(anError) [[NSAlert alertWithError:anError] runModal];
                
                [self exportFinished];
            }];        
        }];
	}
    
    [exportQueue addOperation:exportOperationBlock];
}

#pragma mark thumbnails export

- (NSString *)chooseThumbsExportDirectory {

    NSSavePanel *sPanel = [NSSavePanel savePanel];
	
	[sPanel setAccessoryView:thumbnailsExportAccessoryView];
	[sPanel setCanCreateDirectories:YES];
	
	NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];

	int runResult = [sPanel runModalForDirectory:desktopPath file:@"ResizedImages"];
	
	return (runResult == NSOKButton) ? [sPanel filename] : nil;
}

- (IBAction)resizeJPEGs:(id)sender {
	if(isExporting) return;
	
	NSString *exportDir = [self chooseThumbsExportDirectory];
	if(!exportDir) return;
	
	NSError *error = nil;
	BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:exportDir withIntermediateDirectories:YES attributes:nil error:&error];
	if(!success) {
		NSLog(@"Error: can't create dir at path %@, error: %@", exportDir, error);
//		if(error) {
//		[mainWindow presentError:error
//            modalForWindow:mainWindow
//            delegate:self
//            didPresentSelector:nil
//            contextInfo:nil];
//		}
	}
	
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isExporting"];
	
	NSArray *theImages = [[[imagesController selectedObjects] copy] autorelease];

	[self prepareProgressIndicator:[theImages count]];
	
	int tag = [[NSUserDefaults standardUserDefaults] integerForKey:kThumbsExportSizeTag];
	
	int w = 0;
	int h = 0;
	
	if(tag == 0) {
		w = 300; h = 255;
	} else if (tag == 1) {
		w = 640; h = 480;		
	} else if (tag == 2) {
		w = 800; h = 600;
	} else if (tag == 3) {
		w = [[[NSUserDefaults standardUserDefaults] stringForKey:kThumbsExportSizeWidth] intValue];
		h = [[[NSUserDefaults standardUserDefaults] stringForKey:kThumbsExportSizeHeight] intValue];	
	}

	NSOperationQueue *resizeQueue = [[[NSOperationQueue alloc] init] autorelease];
	
	NSBlockOperation *resizeBlockOperation = [[[NSBlockOperation alloc] init] autorelease];

	for(CSSImageInfo *imageInfo in theImages) {
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[self incrementExportProgress];
		}];

		if([imageInfo isJpeg] == NO) continue;
		
		[resizeBlockOperation addExecutionBlock:^{
			NSString *destPath = [[exportDir stringByAppendingPathComponent:[[imageInfo path] lastPathComponent]] lowercaseString];
			BOOL success = [[imageInfo image] scaleAndSaveAsJPEGWithMaxWidth:w maxHeight:h quality:0.9 destination:destPath];
			if(!success) NSLog(@"Could not scale and save as jpeg into %@", destPath);			
        }];	
	}
	
	[resizeBlockOperation setCompletionBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self exportFinished];
		}];
    }];
	
	[resizeQueue addOperation:resizeBlockOperation];
}

@end
