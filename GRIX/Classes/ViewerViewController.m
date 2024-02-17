
//
//  ViewerViewController.m
//  eboy
//
//  Created by Brian Papa on 8/6/11.
//  Copyright 2011 Felt Tip Inc. All rights reserved.
//

#import "ViewerViewController.h"
#import "ArtboardView.h"
#import "Artboard.h"
#import "ArtboardViewController.h"
#import "ColorPalette.h"
#import "eboyAppDelegate.h"
#import "GalleryAndViewerSegue.h"
#import "DeleteArtboardSegue.h"
#import "GalleryArtboardFrame.h"
#import "UIView+Setup.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/ALAssetsLibrary.h>


const NSTimeInterval ViewerViewControllerCopyingAnimationDuration = 2.0;
const CGFloat ViewerViewControllerCopyingAnimationScale = 0.40;

@implementation ViewerViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Scroll View

- (CGFloat)padding {
    return (self.artboardsScrollView.bounds.size.width - self.view.bounds.size.width) / 2;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGRect bounds = self.artboardsScrollView.bounds;
    CGRect pageFrame = bounds;
    CGFloat padding = [self padding];
    pageFrame.size.width -= (2 * padding);
    pageFrame.origin.x = (bounds.size.width * index) + padding;
    return pageFrame;
}

- (void)setContentSize {
    self.artboardsScrollView.contentSize = CGSizeMake(self.artboardsScrollView.bounds.size.width * self.artboardsCount, self.artboardsScrollView.frame.size.height);
}

- (void)setContentOffsetForPage:(NSInteger)page {
    CGFloat originX = self.artboardsScrollView.bounds.size.width * page;
    [self.artboardsScrollView setContentOffset:CGPointMake(originX, 0.0)];
}

- (void)createArtboardViewWithFrame:(NSDictionary*)artboardViewDictionary {
    NSInteger page = [[artboardViewDictionary objectForKey:@"page"] integerValue];
    CGRect frame= [self frameForPageAtIndex:page];
    Artboard *artboard = [artboardViewDictionary objectForKey:@"artboard"];

    ArtboardView *artboardView = [[ArtboardView alloc] initWithFrame:frame artboard:artboard];
    [self.artboards replaceObjectAtIndex:page withObject:artboardView]; 
    
    // Add gesture recognizer for double-tap to edit
    UITapGestureRecognizer *artboardDoubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(edit:)];
    artboardDoubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [artboardView addGestureRecognizer:artboardDoubleTapGestureRecognizer];
    
    // add the placeholder view to the scroll view
    [self.artboardsScrollView addSubview:artboardView];
}

- (void)loadScrollViewWithPage:(NSInteger)page
{
    if (page < 0)
        return;
    if (page >= self.artboardsCount)
        return;
    
    CGRect frame= [self frameForPageAtIndex:page];
	
    ArtboardView *currentArtboardView = [self.artboards objectAtIndex:page];
    if ((NSNull*)currentArtboardView == [NSNull null]) {        
        // fetch the artboard
        Artboard *anArtboard = [Artboard artboardAtIndex:page managedObjectContext:self.managedObjectContext];
                    
        // do the actual artboard view creation and addition on the main thread
		NSDictionary *artboardViewDictionary = @{@"page":@(page), @"artboard":anArtboard};
        [self performSelectorOnMainThread:@selector(createArtboardViewWithFrame:) withObject:artboardViewDictionary waitUntilDone:NO];
    } else {
        // ensure proper frame is set
        currentArtboardView.frame = frame;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{		
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.artboardsScrollView.frame.size.width;
    NSInteger page = floor((self.artboardsScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if (page != self.visibleArtboardIndex) {
        self.visibleArtboardIndex = page;
        
        // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
        [self loadScrollViewWithPage:self.visibleArtboardIndex - 1];
        [self loadScrollViewWithPage:self.visibleArtboardIndex];
        [self loadScrollViewWithPage:self.visibleArtboardIndex + 1];
		
		// Sound effect
		[UIAppDelegate.soundEffects playColorPaletteClickSound];
        
        // update saved location
        [UIAppDelegate.savedLocation replaceObjectAtIndex:0 withObject:@(self.visibleArtboardIndex)];
    }
    
    // A possible optimization would be to unload the views+controllers which are no longer visible
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set these since we aren't using a standard UIToolbar, and to prevent unlocking of an Artboard at the same time that a button is pressed
	[self.topToolbar setupSubviewsToBePixelatedAndExclusiveTouch];
	[self.bottomToolbarContainer setupSubviewsToBePixelatedAndExclusiveTouch];
    self.artboardsScrollView.exclusiveTouch = YES;
    
    // track the initial ordering in case user changes later via settings app
    self.isDescendingOrder = ![Artboard artboardsOrderIsAscending];    
    
    NSInteger theCount = [Artboard countArtboardsWithManagedObjectContext:self.managedObjectContext];
    self.artboardsCount = theCount;
    
    self.artboards = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < self.artboardsCount; i++) {
		[self.artboards addObject:[NSNull null]];
    }
    
    [self setContentSize];
    
    [self loadScrollViewWithPage:self.visibleArtboardIndex];
    [self loadScrollViewWithPage:self.visibleArtboardIndex - 1];
    [self loadScrollViewWithPage:self.visibleArtboardIndex + 1];

    [self.artboardsScrollView setContentOffset:CGPointMake(self.artboardsScrollView.frame.size.width * self.visibleArtboardIndex, 0.0)];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    [self setContentOffsetForPage:self.visibleArtboardIndex];
    
    for (id anObject in self.artboards) {
        if ([anObject isKindOfClass:[ArtboardView class]]) {
            // need to draw any changes made if coming from edit mode
            ArtboardView *artboardView = (ArtboardView*)anObject;
			[artboardView redrawArtboardImage];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [UIAppDelegate saveContext];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // clear the saved location
    [UIAppDelegate.savedLocation replaceObjectAtIndex:1 withObject:@(-1)];
}

#pragma mark -
#pragma mark Restore Application State
- (void)restoreLevelWithSelectionArray:(NSArray *)selectionArray {	
    NSInteger artboardIndex = [[selectionArray objectAtIndex:0] integerValue];
    if (artboardIndex != -1) {        
        // load the Artboard for the Artboard VC
        Artboard *editingArtboard = [Artboard artboardAtIndex:artboardIndex managedObjectContext:self.managedObjectContext];
        
        // if no artboard was loaded, then stop trying to restore
        if (editingArtboard) {    
            // move in editor
            ArtboardViewController *artboardViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Editor"];
            
            // pass along the MOC
            artboardViewController.managedObjectContext = self.managedObjectContext;
            
            artboardViewController.artboard = editingArtboard;
            
            // "wake" the artboard VC
            [self.navigationController pushViewController:artboardViewController animated:NO];
            
            // narrow down the selection array for the artboard
            NSArray *newSelectionArray = [selectionArray subarrayWithRange:NSMakeRange(1, [selectionArray count]-1)];
            
            // restore that level
            [artboardViewController restoreLevelWithSelectionArray:newSelectionArray];
        }
    }
}

#pragma mark - Disable/Enable UI

- (void)disableUIForSheet {
    // change rest of UI
    self.artboardsScrollView.userInteractionEnabled = NO;
	[self.topToolbar setSubviewsEnabled:NO];
	[self.bottomToolbarContainer setSubviewsEnabled:NO];
}

- (void)reenableUIForSheet {
    // change rest of UI
    self.artboardsScrollView.userInteractionEnabled = YES;
	[self.topToolbar setSubviewsEnabled:YES];
	[self.bottomToolbarContainer setSubviewsEnabled:YES];
}

#pragma mark - Actions

- (IBAction)duplicate:(id)sender {
	// Disable the buttons.
	[self disableUIForSheet];
	
	// duplicate in the model
    ArtboardView *visibleArtboardView = self.visibleArtboardView;
    Artboard *duplicateArtboard = [visibleArtboardView.artboard duplicate];
            
    // local count needs to be updated
    self.artboardsCount++;
    
    // create a new artboard view and add it to the scroll view
    CGAffineTransform artboardScaleTransform = CGAffineTransformMakeScale(ViewerViewControllerCopyingAnimationScale, ViewerViewControllerCopyingAnimationScale);
    CGAffineTransform artboardTranslateTransform = CGAffineTransformMakeTranslation(visibleArtboardView.frame.size.width / -4, 0.0);
    ArtboardView *duplicateArtboardView = [[ArtboardView alloc] initWithFrame:visibleArtboardView.frame artboard:duplicateArtboard];
	[duplicateArtboardView redrawArtboardImage];
    
    // index depends on sort order preference
    if (self.isDescendingOrder)
        [self.artboards insertObject:duplicateArtboardView atIndex:0];
    else    
        [self.artboards addObject:duplicateArtboardView];
    
    // put a frame behind both artboard views
    GalleryArtboardFrame *visibleArtboardViewFrame = [[GalleryArtboardFrame alloc] initWithFrame:CGRectInset(visibleArtboardView.frame, -4.0, -4.0)];
    [self.artboardsScrollView insertSubview:visibleArtboardViewFrame belowSubview:visibleArtboardView];
    GalleryArtboardFrame *duplicateArtboardViewFrame = [[GalleryArtboardFrame alloc] initWithFrame:CGRectInset(duplicateArtboardView.frame, -4.0, -4.0)];
    
    // set the initial transform for the duplicate
    duplicateArtboardView.transform = CGAffineTransformConcat(artboardScaleTransform, artboardTranslateTransform);
    duplicateArtboardViewFrame.transform = CGAffineTransformConcat(artboardScaleTransform, artboardTranslateTransform);
    
    NSTimeInterval animationStepDuration = ViewerViewControllerCopyingAnimationDuration / 3;
    
    [UIView animateWithDuration:animationStepDuration animations:^(void) {
        // Part 1. Scale down the current artboard and move it over a tad.
        visibleArtboardViewFrame.transform = CGAffineTransformConcat(artboardScaleTransform, artboardTranslateTransform);
        visibleArtboardView.transform = CGAffineTransformConcat(artboardScaleTransform, artboardTranslateTransform);
    } completion:^(BOOL finished) {
        // Add the duplicate behind the original.
        [self.artboardsScrollView insertSubview:duplicateArtboardView belowSubview:visibleArtboardViewFrame];
        [self.artboardsScrollView insertSubview:duplicateArtboardViewFrame belowSubview:duplicateArtboardView];
        [UIView animateWithDuration:animationStepDuration animations:^(void) {
            // Part 2. The duplicated artboard is "pulled out" from behind the original.
            CGAffineTransform duplicateTranslateTransform = CGAffineTransformMakeTranslation(-artboardTranslateTransform.tx, 0.0);
            duplicateArtboardViewFrame.transform = CGAffineTransformConcat(artboardScaleTransform, duplicateTranslateTransform);
            duplicateArtboardView.transform = CGAffineTransformConcat(artboardScaleTransform, duplicateTranslateTransform);
        } completion:^(BOOL finished) {
			// Send the original artboard and its frame to the back.
			[self.artboardsScrollView sendSubviewToBack:visibleArtboardView];
			[self.artboardsScrollView sendSubviewToBack:visibleArtboardViewFrame];
			
            [UIView animateWithDuration:animationStepDuration animations:^(void) {
                duplicateArtboardViewFrame.transform = CGAffineTransformIdentity;
                duplicateArtboardView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                // Part 3. Return original artboard to normal
                [visibleArtboardViewFrame removeFromSuperview];
                visibleArtboardView.transform = CGAffineTransformIdentity;
                
                // move duplicate artboard view to correct spot in scroll view, depending on sort order preference
                if (self.isDescendingOrder)
                    self.visibleArtboardIndex = 0;
                else
                    self.visibleArtboardIndex = self.artboards.count - 1;
                duplicateArtboardView.frame = [self frameForPageAtIndex:self.visibleArtboardIndex];
                [self setContentSize];
                [self setContentOffsetForPage:self.visibleArtboardIndex];
                [duplicateArtboardViewFrame removeFromSuperview];
                
                // if the duplicate was inserted first (descending order) all other artboards must be moved over 
                if (self.isDescendingOrder) {
                    for (NSInteger i = 1; i < self.artboards.count; i++) {
                        id possibleView = [self.artboards objectAtIndex:i];
                        if ((NSNull*)possibleView != [NSNull null]) {
                            ArtboardView *currentArtboardView = (ArtboardView*)possibleView;
                            currentArtboardView.frame = [self frameForPageAtIndex:i];
                        }
                    }
                }
                
                // queue up previous/next artboard in case user wants to swipe back
                [self loadScrollViewWithPage:self.visibleArtboardIndex - 1];
                [self loadScrollViewWithPage:self.visibleArtboardIndex + 1];
 
				[self reenableUIForSheet];
                
                // update saved location
                [UIAppDelegate.savedLocation replaceObjectAtIndex:0 withObject:@(self.visibleArtboardIndex)];
                
                // send notification so that interested parties are aware
                [[NSNotificationCenter defaultCenter] postNotificationName:ArtboardDuplicatedNotification object:duplicateArtboard];
            }];
        }];
    }];

	// Start sound effect for duplicate here, after all the set up is done, but before animations start.
	[UIAppDelegate.soundEffects playDuplicateArtboardSound];
	
	// Save context while the animations are running.
	[UIAppDelegate performSelector:@selector(saveContext) withObject:nil afterDelay:0.25];
}

- (IBAction)back:(id)sender {
    // this is a total kludge, probably not the best way to do this. It seems like segues have no concept of "back", so to "undo" the animations, I'm instantiating a new segue and then calling the perform method on it.
    UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
    GalleryAndViewerSegue *segue = [[GalleryAndViewerSegue alloc] initWithIdentifier:@"artboardViewerSegue" source:self destination:previousViewController];
    [segue perform];
}

- (IBAction)edit:(id)sender {
    [self performSegueWithIdentifier:@"edit" sender:sender];
}

#pragma mark -  Getters
- (ArtboardView*)visibleArtboardView {
    return [self.artboards objectAtIndex:self.visibleArtboardIndex];
}

#pragma mark - Sharing Options

- (IBAction)showShareSheet:(id)sender {
	// Use the system-provided Share Sheet.
	NSString *message = NSLocalizedString(@"I made this with #thegrix.", @"Message text for use in Share feature.");
	UIImage *image = [self.visibleArtboardView renderedImageWithScaleFactor:8.0];
	NSData *imagePngData = UIImagePNGRepresentation(image);

	NSData *artData = [self.visibleArtboardView.artboard dataForExport];
	NSURL *artURL = nil;
	if (artData != nil) {
		NSString *filename = @"Grix File.grix";
		artURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:filename]];
		[artData writeToURL:artURL atomically:NO];
	}
	
	NSMutableArray *items = [NSMutableArray arrayWithCapacity:4];
	[items addObject:message];
	if (artURL) [items addObject:artURL];
	if (imagePngData) {
		[items addObject:imagePngData];
	} else {
		NSLog(@"PNG image missing, using JPEG image");
		[items addObject:image];
	}

	UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
	vc.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		NSError *error = nil;
		if ([[NSFileManager defaultManager] removeItemAtURL:artURL error:&error] == NO) {
			NSLog(@"Error deleting temp file for Grix file attachment. Error: %@", error);
		}
	};
	[self presentViewController:vc animated:YES completion:nil];
}

- (NSString *)uniqueTempFilename {
	// Filename with date and time.
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"yyyy-MM-dd 'at' HH_mm_ss";
	NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
	NSString *fileNamePrefix = NSLocalizedString(@"Grix at ", @"Email filename prefix.");
	return [fileNamePrefix stringByAppendingString:dateString];
}

- (void)dimScreenWithSpinner:(BOOL)spin {
	self.screenDimmerOverlayView.frame = self.view.frame;
    [self.view addSubview:self.screenDimmerOverlayView];
	self.screenDimmerSpinner.hidden = !spin;
}

- (void)removeOverlay {
	[self.screenDimmerOverlayView removeFromSuperview];
}

#pragma mark - Delete Artboard

- (IBAction)showDeleteSheet:(id)sender {
    [self dimScreenWithSpinner:NO];
    
    [[NSBundle mainBundle] loadNibNamed:@"DeleteImageActionSheetView" owner:self options:nil];
	[self.deleteImageActionSheetView setupSubviewsToBePixelatedAndExclusiveTouch];
    
    // the delete sheet begins off-screen then slides up like an action sheet
    CGSize viewSize = self.navigationController.view.frame.size;
    CGSize deleteSheetSize = self.deleteImageActionSheetView.frame.size;
    self.deleteImageActionSheetView.frame = CGRectMake(0.0, viewSize.height, deleteSheetSize.width, deleteSheetSize.height);
    [self.navigationController.view addSubview:self.deleteImageActionSheetView];
    CGRect deleteSheetDestinationFrame = CGRectMake(0.0, viewSize.height - deleteSheetSize.height, deleteSheetSize.width, deleteSheetSize.height);
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.deleteImageActionSheetView.frame = deleteSheetDestinationFrame;
                     }
     ];
	
    [self disableUIForSheet];
	[UIAppDelegate.soundEffects playOpenSheetSound];
}

- (void)slideOutDeleteSheet {
    // share sheet slides back down off screen
    CGSize viewSize = self.navigationController.view.frame.size;
    CGRect deleteSheetDestinationFrame = CGRectMake(0.0, viewSize.height, self.deleteImageActionSheetView.frame.size.width, self.deleteImageActionSheetView.frame.size.height);
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.deleteImageActionSheetView.frame = deleteSheetDestinationFrame;
                     }
                     completion:^(BOOL finished){
                         [self.deleteImageActionSheetView removeFromSuperview];
                     }];

	[UIAppDelegate.soundEffects playCloseSheetSound];
}

- (IBAction)confirmDeleteImage:(id)sender {
	[self removeOverlay];
	[self slideOutDeleteSheet];

	UIViewController *previous = [self.navigationController.viewControllers objectAtIndex:0];
	DeleteArtboardSegue *deleteSegue = [[DeleteArtboardSegue alloc] initWithIdentifier:@"deleteArtboard" source:self destination:previous];
	[deleteSegue perform];
	// Artboard is actually deleted at the end of the segue.
}

- (IBAction)cancelDeleteImage:(id)sender {
    [self removeOverlay];
    
    [self slideOutDeleteSheet];
    
    [self reenableUIForSheet];
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"edit"]) {
        ArtboardViewController *artboardController = segue.destinationViewController;
        
        // pass along the MOC
        artboardController.managedObjectContext = self.managedObjectContext;
        
        // assign the artboard for the view controller
        Artboard *artboard = self.visibleArtboardView.artboard;
        artboardController.artboard = artboard;

        // save this to the saved location array
        [UIAppDelegate.savedLocation replaceObjectAtIndex:1 withObject:@(self.visibleArtboardIndex)];
    }
}

@end
