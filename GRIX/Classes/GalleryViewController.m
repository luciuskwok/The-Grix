//
//  GalleryViewController.m
//  eboy
//
//  Created by Brian Papa on 8/6/11.
//  Copyright 2011 Felt Tip Inc. All rights reserved.
//

#import "GalleryViewController.h"
#import "Artboard.h"
#import "ViewerViewController.h"
#import "ArtboardViewController.h"
#import "eboyAppDelegate.h"
#import "UIView+Setup.h"
#import <QuartzCore/QuartzCore.h>

const CGFloat GalleryThumbnailGap = 16.0;
const CGFloat GalleryThumbnailFrameInset = 4.0;
const NSInteger GalleryThumbnailsInRow = 4;
const NSInteger GalleryArtboardFrameViewTagStart = 1000;
const NSTimeInterval GalleryMoveArtboardsAfterDeletionDuration = .5;

@implementation GalleryViewController


#pragma mark - Instance methods

- (void)awakeFromNib {
	[super awakeFromNib];
	
    // if this VC is loaded from the storyboard file set its MOC as the main one in the App Delegate
    self.managedObjectContext = UIAppDelegate.managedObjectContext;
	
	// Save persistentStoreCoordinator for thread
	self.persistentStoreCoordinator = [UIAppDelegate persistentStoreCoordinator];
    
	// Register for notifications
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(artboardEdited:) name:ArtboardEditedNotification object:nil];
    [nc addObserver:self selector:@selector(artboardDuplicated:) name:ArtboardDuplicatedNotification object:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Image view private methods

- (void)updateContentSize {
    NSInteger artboardsCount = [Artboard countArtboardsWithManagedObjectContext:self.managedObjectContext];
    
	UIScrollView *sv = self.artboardsScrollView;
	CGFloat w = sv.frame.size.width - sv.contentInset.left - sv.contentInset.right;
	NSInteger rows = (artboardsCount + GalleryThumbnailsInRow - 1) / GalleryThumbnailsInRow;
	CGFloat h = rows * (GalleryThumbnailSize + GalleryThumbnailGap) - GalleryThumbnailGap;
	[self.artboardsScrollView setContentSize:CGSizeMake(w, h)];
}

- (UIView *)containerViewWithImage:(UIImage*)image index:(NSUInteger)index {
	CGRect frameRect = [self artboardFrameRectForIndex:index];

	// Artboard image view
	UIImageView *artboardImageView = [[UIImageView alloc] initWithImage:image];
    artboardImageView.frame = CGRectMake(4.0, 4.0, GalleryThumbnailSize, GalleryThumbnailSize);
	artboardImageView.layer.magnificationFilter = kCAFilterNearest;

	// Artboard frame view
	GalleryArtboardFrame *artboardFrameView = [[GalleryArtboardFrame alloc] initWithFrame:CGRectMake(0, 0, frameRect.size.width, frameRect.size.height)];
	[artboardFrameView addSubview:artboardImageView];

	// Use a container UIView so that its contents can be swapped out even during animations.
	UIView *containerView = [[UIView alloc] initWithFrame:frameRect];
	containerView.tag = index + GalleryArtboardFrameViewTagStart;
	[containerView addSubview:artboardFrameView];

	return containerView;
}

#pragma mark - Image view public methods

- (UIView *)artboardFrameViewAtIndex:(NSInteger)index {
	return [self.artboardsScrollView viewWithTag: index + GalleryArtboardFrameViewTagStart];
}

- (void)setArtboardImage:(UIImage*)image atIndex:(NSInteger)index {
	// Replace the container view's subview but don't change the container view itself.
	UIView *containerView = [self.artboardsScrollView viewWithTag: index + GalleryArtboardFrameViewTagStart];
	if (containerView.subviews.count > 0) {
		// Remove the old view, which is either a UIImageView of the placeholder image, or the old gallery frame view.
		UIView *oldView = [containerView.subviews objectAtIndex:0];
		[oldView removeFromSuperview];
	
		// Insert new view.
		UIView *tempContainerView = [self containerViewWithImage:image index:index];
		UIView *newFrameView = [tempContainerView.subviews objectAtIndex:0];
		[newFrameView removeFromSuperview];
		[containerView addSubview:newFrameView];
	}
}

- (CGRect)artboardFrameRectForIndex:(NSInteger)index {
	CGFloat spacing = GalleryThumbnailSize + GalleryThumbnailGap;
    CGFloat x = (index % GalleryThumbnailsInRow) * spacing;
    CGFloat y = (index / GalleryThumbnailsInRow) * spacing;
	CGRect box = CGRectMake(x, y, GalleryThumbnailSize, GalleryThumbnailSize);
    return CGRectInset(box, -GalleryThumbnailFrameInset, -GalleryThumbnailFrameInset);
}

- (void)addArtboard:(Artboard *)artboard {
	NSUInteger newArtboardIndex = [Artboard artboardsOrderIsAscending]? self.artboards.count : 0;
	
    // if the artboard is added at the front, all of the other artboards need their frames and tags updated
    if (newArtboardIndex == 0) {
        for (NSInteger i = self.artboards.count - 1; i >= 0; i--) {
            UIView *frameView = [self.artboardsScrollView viewWithTag: GalleryArtboardFrameViewTagStart + i];
            frameView.frame = [self artboardFrameRectForIndex:i + 1];
			frameView.tag = GalleryArtboardFrameViewTagStart + i + 1;
        }
    }
	
	NSMutableArray *newArtboards = [NSMutableArray arrayWithArray:self.artboards];
	[newArtboards insertObject:artboard atIndex:newArtboardIndex];
	self.artboards = newArtboards;
	
    // Update content size to make room for new artboard
	[self updateContentSize];
	
	// Add frame to scroll view
	UIImage *image = [artboard renderedImage];
	UIView *frameView = [self containerViewWithImage:image index:newArtboardIndex];
	[self.artboardsScrollView addSubview:frameView];
	
}

#pragma mark - Update for storyboard segues

- (void)setRenderingStartIndexForSelectedIndex:(NSInteger)index {
	// Call this before view is loaded so that the render thread can start working on artboards starting at the correct position.
	// This sets the start index to the artboard that is 5 rows above the currently selected one, so that the all visible artboards are rendered first. 
	NSInteger row = index / GalleryThumbnailsInRow - 5;
	if (row < 0)
		row = 0;
	self.renderingStartIndex = row * GalleryThumbnailsInRow;
}

- (void)deleteArtboardAtIndex:(NSInteger)index {
	[self.renderingDeletedLock lock];
	self.artboardWasDeleted = YES;
	Artboard *deletedArtboard = [self.artboards objectAtIndex:index];
	[Artboard deleteArtboard:deletedArtboard];
	self.artboards = [Artboard artboardsWithManagedObjectContext:self.managedObjectContext prefetch:NO];
	[self.renderingDeletedLock unlock];
	
	// Remove image for deleted artboard.
	UIView *deletedView = [self artboardFrameViewAtIndex:index];
	[deletedView removeFromSuperview];
	
	// Adjust frame rect of all artboards after the deleted one.
	CGRect scrollViewBounds = self.artboardsScrollView.bounds;
	for (NSUInteger moveIndex = index; moveIndex < self.artboards.count; moveIndex++) {
		UIView *moveView = [self.artboardsScrollView viewWithTag:moveIndex + GalleryArtboardFrameViewTagStart + 1];
		CGRect destinationRect = [self artboardFrameRectForIndex:moveIndex];
		// Animate views that will become visible
		if (CGRectIntersectsRect(scrollViewBounds, destinationRect)) {
			[UIView animateWithDuration:GalleryMoveArtboardsAfterDeletionDuration animations:^{
				moveView.frame = destinationRect;
			}];
		} else {
			moveView.frame = destinationRect;
		}
		// Update tag
		moveView.tag = moveIndex + GalleryArtboardFrameViewTagStart;
	}
    
    // put an explosion in the deleted artboards place
    CGRect explosionFrame = [self artboardFrameRectForIndex:index];
    UIImageView *explosionImageView = [[UIImageView alloc] initWithFrame:explosionFrame];
    NSMutableArray *animationImages = [NSMutableArray array];
    for (int i = 1; i <= 7; i++)
        [animationImages addObject:[UIImage imageNamed:[NSString stringWithFormat:@"explosion%d.png",i]]];
    explosionImageView.animationImages = animationImages;
    explosionImageView.animationDuration = GalleryMoveArtboardsAfterDeletionDuration/2;
    explosionImageView.animationRepeatCount = 1;
    
    [self.artboardsScrollView addSubview:explosionImageView];
    [explosionImageView startAnimating];
    [explosionImageView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:GalleryMoveArtboardsAfterDeletionDuration];    
}

#pragma mark - Threading

- (void)replacePlaceholderWithParameters:(NSDictionary *)parameters {
	// This method should run on the main thread.
	UIImage *image = [parameters objectForKey:@"image"];
	NSManagedObjectID *objectID = [parameters objectForKey:@"objectID"];
	
	// Find the index of the matching object.
	NSUInteger index = 0;
	BOOL found = NO;
	for (Artboard *artboard in self.artboards) {
		if ([artboard.objectID isEqual:objectID]) {
			[self setArtboardImage:image atIndex:index];
			found = YES;
			break;
		}
		index++;
	}
	if (found == NO) 
		NSLog(@"Unmatched objectID for rendered artboard image: %@", objectID);
}

- (void)renderArtboardImageThread {
	TimingLoggingStart
	
	// Create managed object context for this thread.
	NSManagedObjectContext *threadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
	[threadContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];

	// Validate the start index
	NSInteger count = [Artboard countArtboardsWithManagedObjectContext:threadContext];
	if (self.renderingStartIndex < 0 || self.renderingStartIndex >= count)
		self.renderingStartIndex = 0;
	
	// Load artboards in batches of 4. This speeds up the fetch requests by 29%.
	const NSInteger numberOfItemsPerBatch = 4;
	NSRange range = NSMakeRange(self.renderingStartIndex, numberOfItemsPerBatch);
	NSInteger remaining = count;
	
	while (remaining > 0) {
		range.length = numberOfItemsPerBatch;
		if (range.length > count - range.location)
			range.length = count - range.location;
		
		// Go back by one if an artboard at or before the range location was deleted. Then clear the ivar since it's no longer needed.
		[self.renderingDeletedLock lock];
		if (self.artboardWasDeleted) {
			if (range.location > 0) 
				range.location--;
			self.artboardWasDeleted = NO;
		}
		NSArray *threadArtboards = [Artboard artboardsInRange:range withManagedObjectContext:threadContext];
		[self.renderingDeletedLock unlock];
		
		for (Artboard *artboard in threadArtboards) {
			UIImage *image = [artboard renderedImageWithTileToSkip:nil shadow:YES shadowColor:self.shadowColor backgroundColor:self.backgroundColor];
			NSDictionary *parameters = @{@"image":image, @"objectID":artboard.objectID};
			[self performSelectorOnMainThread:@selector(replacePlaceholderWithParameters:) withObject:parameters waitUntilDone:NO];
		}
		
		range.location += range.length;
		remaining -= range.length;
		
		if (range.location >= count)
			range.location = 0;
	}
	
 	TimingLoggingMark(renderArtboardImageThread)
}

#pragma mark - Gesture Recognizer handlers

- (IBAction)handleArtboardScrollViewTap:(UITapGestureRecognizer*)recognizer {
    // determine which artboard was tapped
    CGPoint tappedPoint = [recognizer locationInView:self.artboardsScrollView];
	for (UIView *frameView in self.artboardsScrollView.subviews) {
		if (CGRectContainsPoint(frameView.frame, tappedPoint)) {
			self.isDoubleSegue = NO;
			[self performSegueWithIdentifier:@"artboardViewerSegue" sender:frameView];
			return;
		}
	}
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set these since we aren't using a standard UIToolbar, and to prevent selection of an Artboard at the same time that a button is pressed
    self.artboardsScrollView.exclusiveTouch = YES;
	
	// Also set the layer's magnification filter to nearest so that it scales properly on the iPad at 2x.
	[self.topToolbar setupSubviewsToBePixelatedAndExclusiveTouch];
    
	self.artboards = [Artboard artboardsWithManagedObjectContext:self.managedObjectContext prefetch:NO];
	
	// Lay out placeholder images in the scroll view, to be replaced with the actual artboards when they are ready.
	[self updateContentSize];
	
	// Do not remove existing subviews from the scroll view, because it seems one of the subviews is the scroller.
	
	UIImage *placeholderImage = [UIImage imageNamed:@"artboardPlaceholderImage.png"];
	for (NSInteger index = 0; index < self.artboards.count; index++) {
		CGRect frameRect = [self artboardFrameRectForIndex:index];
		UIImageView *placeholderView = [[UIImageView alloc] initWithImage:placeholderImage];
		placeholderView.frame = CGRectMake(0, 0, frameRect.size.width, frameRect.size.height);
		
		UIView *containerView = [[UIView alloc] initWithFrame:frameRect];
		containerView.tag = index + GalleryArtboardFrameViewTagStart;
		[containerView addSubview:placeholderView];
		[self.artboardsScrollView addSubview:containerView];
	}
         
	// Scroll to top left.
	UIEdgeInsets scrollViewInset = self.artboardsScrollView.contentInset;
    [self.artboardsScrollView setContentOffset:CGPointMake(-scrollViewInset.left, -scrollViewInset.top)];
	
	// Add gesture recognizer.
	UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleArtboardScrollViewTap:)];
	[self.artboardsScrollView addGestureRecognizer:recognizer];

	// If an artboard is deleted while the rendering thread is running, the thread's fetchOffset will be incorrect, so there needs to be an ivar to signal that condition.
	self.renderingDeletedLock = [[NSLock alloc] init];
	
	// Start thread to render artboard images.
	self.backgroundColor = [UIAppDelegate colorWithUIColor:UIAppDelegate.artboardBackgroundColor]; // Update background color.
	self.shadowColor = [UIAppDelegate colorWithUIColor:UIAppDelegate.shadowColor]; // Update background color.
	[NSThread detachNewThreadSelector:@selector(renderArtboardImageThread) toTarget:self withObject:nil];

	// if this is the first time that he user has launched the app, show them the tutorial artboard in edit mode
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultsKeyInitialLaunchCompleted"] == NO) {
		[self jumpToEditorWithArtboardIndex:0];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DefaultsKeyInitialLaunchCompleted"];
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
        
    // clear the saved location
    [UIAppDelegate.savedLocation replaceObjectAtIndex:0 withObject:@(-1)];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"artboardViewerSegue"]) {
        // figure out which artboard view was tapped and what index it is
		NSInteger index = [sender tag] - GalleryArtboardFrameViewTagStart;
		if (index >= 0 && index < self.artboards.count) {
			ViewerViewController *viewerController = segue.destinationViewController;
			viewerController.visibleArtboardIndex = index;
			
			// pass along MOC
			viewerController.managedObjectContext = self.managedObjectContext;
			
			// save this to the saved location array
			[UIAppDelegate.savedLocation replaceObjectAtIndex:0 withObject:@(index)];
		}
	} else if ([segue.identifier isEqualToString:@"info"]) {
    }
}

- (void)jumpToEditorWithArtboardIndex:(NSInteger)index {
	UIView *frameView = [self artboardFrameViewAtIndex:index];
	self.isDoubleSegue = YES;
	[self performSegueWithIdentifier:@"artboardViewerSegue" sender:frameView];
	[self performSelector:@selector(openEditorInTopNavController) withObject:nil afterDelay:1.0];
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
}

- (void)openEditorInTopNavController {
	ViewerViewController *viewer = (ViewerViewController *)self.navigationController.topViewController;
	if ([viewer respondsToSelector:@selector(edit:)]) {
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		[viewer edit:nil];
	}
}

#pragma mark - IBActions

- (IBAction)createNewArtboard:(id)sender
{
	Artboard *newArtboard = [Artboard newArtboardWithManagedObjectContext:self.managedObjectContext];
	[self addArtboard:newArtboard];
	NSInteger index = [Artboard artboardsOrderIsAscending]? self.artboards.count: 0;
	[self jumpToEditorWithArtboardIndex:index];
}

#pragma mark - Restore Application State

- (void)restoreLevelWithSelectionArray:(NSArray *)selectionArray {
	NSInteger artboardIndex = [[selectionArray objectAtIndex:0] integerValue];
    if (artboardIndex != -1) {        
        // count artboards to make sure valid
        if (artboardIndex < [Artboard countArtboardsWithManagedObjectContext:self.managedObjectContext]) {            
            // move in viewer and restore its content (not animated since the user should not see the restore process)
            ViewerViewController *viewer = [self.storyboard instantiateViewControllerWithIdentifier:@"Viewer"];
            viewer.visibleArtboardIndex = artboardIndex;
            
            // pass along the MOC
            viewer.managedObjectContext = self.managedObjectContext;
            
            // "wake" the Viewer VC
            [self.navigationController pushViewController:viewer animated:NO];
            
            // narrow down the selection array for the artboard
            NSArray *newSelectionArray = [selectionArray subarrayWithRange:NSMakeRange(1, [selectionArray count]-1)];
            
            // update the scroll view so that the content offset is correct
			[self.artboardsScrollView scrollRectToVisible:[self artboardFrameRectForIndex:artboardIndex] animated:NO];
            
            // restore that level
            [viewer restoreLevelWithSelectionArray:newSelectionArray];
        }
    }
}

#pragma mark - Artboard notifications

- (void)artboardDuplicated:(NSNotification *)notification { 
	Artboard *newArtboard = [notification object];
	[self addArtboard:newArtboard];
}

- (void)artboardEdited:(NSNotification *)notification {
    NSManagedObjectID *editedArtboardID = [notification object];
    Artboard *artboard = (Artboard*)[self.managedObjectContext objectWithID:editedArtboardID];
	NSUInteger index = [self.artboards indexOfObject:artboard];
	[self setArtboardImage:[artboard renderedImage] atIndex:index];
}

@end
