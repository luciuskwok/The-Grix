//
//  OpenArtboardViewerStoryboardSegue.m
//  eboy
//
//  Created by Brian Papa on 9/26/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "GalleryAndViewerSegue.h"
#import "GalleryViewController.h"
#import "ViewerViewController.h"
#import "Artboard.h"
#import "eboyAppDelegate.h"
#import "ArtboardStoryboardSegue.h"
#import <QuartzCore/QuartzCore.h>

const NSTimeInterval SegueOpenArtboardDuration = 0.5;
CGFloat GallerySegueArtboardEndInset = 20.0;

@implementation GalleryAndViewerSegue

- (void)transitionFromGallery:(GalleryViewController *)gallery toViewer:(ViewerViewController *)viewer {
	// == Transition from Gallery to Viewer ==
	gallery = self.sourceViewController;
	viewer = self.destinationViewController;
	
	// Cause view to load.
	[viewer view];

	// Create image views for frame and artboard image
	NSInteger selectedIndex = viewer.visibleArtboardIndex;
	UIImage *artboardImage = [[gallery.artboards objectAtIndex:selectedIndex] renderedImage];
    UIImageView *artboardImageView = [[UIImageView alloc] initWithImage:artboardImage];
	artboardImageView.layer.magnificationFilter = kCAFilterNearest;
    UIImageView *frameImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"galleryFrameImage"]];
	frameImageView.layer.magnificationFilter = kCAFilterNearest;
	
	// Starting frame rects
	CGRect frameStart = [gallery.view convertRect:[gallery artboardFrameRectForIndex:selectedIndex] fromView:gallery.artboardsScrollView];
    frameImageView.frame = frameStart;
	artboardImageView.frame = CGRectInset(frameStart, 4.0, 4.0);

	// Ending frame rects
	CGRect artboardEnd = CGRectMake(0.0, 40.0, 320.0, 320);
	CGRect frameEnd = CGRectInset(artboardEnd, -GallerySegueArtboardEndInset, -GallerySegueArtboardEndInset);
	
	// Add image views to current view
	[gallery.view insertSubview:frameImageView belowSubview:gallery.topToolbar];
	[gallery.view insertSubview:artboardImageView belowSubview:gallery.topToolbar];
	
    // hide the artboard being viewed
 	UIView *frameView = [gallery artboardFrameViewAtIndex:selectedIndex];
	frameView.hidden = YES;
	
	// Top toolbar slides in from top.
	UIImageView *topToolbar = [self imageViewOfView:viewer.topToolbar withTopLevelView:viewer.view];
	CGRect topToolbarEnd = viewer.topToolbar.frame;
	CGRect topToolbarStart = topToolbarEnd;
	topToolbarStart.origin.y -= topToolbarEnd.size.height;
	topToolbar.frame = topToolbarStart;
	[gallery.view addSubview:topToolbar];
	
	// Bottom toolbar slides up from bottom.
	CGFloat top = viewer.artboardsScrollView.frame.origin.y + viewer.artboardsScrollView.frame.size.height;
	CGRect bottomToolbarStart = CGRectMake(0.0, viewer.view.bounds.size.height, viewer.view.bounds.size.width, viewer.view.bounds.size.height - top);
	CGRect bottomToolbarEnd = bottomToolbarStart;
	bottomToolbarEnd.origin.y -= bottomToolbarEnd.size.height;
	viewer.bottomToolbarContainer.frame = bottomToolbarStart;
	UIImageView *bottomToolbar = [self imageViewOfView:viewer.bottomToolbarContainer withTopLevelView:viewer.view];
	bottomToolbar.frame = bottomToolbarStart;
	bottomToolbar.contentMode = UIViewContentModeBottom;
	[gallery.view addSubview:bottomToolbar];
	
	// Also adjust the size of the toolbar in the actual view.
	viewer.bottomToolbarContainer.frame = bottomToolbarEnd;
	
	// Disable UI interaction during animation.
	if (gallery.isDoubleSegue == NO) {
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	}
	
	// == Animation Block ==
	[UIView animateWithDuration:SegueOpenArtboardDuration animations:^{
		artboardImageView.frame = artboardEnd;
		frameImageView.frame = frameEnd;
		topToolbar.frame = topToolbarEnd;
		bottomToolbar.frame = bottomToolbarEnd;
	} completion:^(BOOL finished) {
		[gallery.navigationController pushViewController:viewer animated:NO]; 
		// Remove added views.
		[artboardImageView removeFromSuperview];
		[frameImageView removeFromSuperview];
		[topToolbar removeFromSuperview];
		[bottomToolbar removeFromSuperview];
		
		if (gallery.isDoubleSegue == NO) {
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		}
        
        // unhide the artboard being viewed
        frameView.hidden = NO;
	}];
	
	// == Sound effects ==
	[UIAppDelegate.soundEffects playOpenViewerSound];	
}

- (void)transitionFromViewer:(ViewerViewController *)viewer toGallery:(GalleryViewController *)gallery {
	// == Transition from Viewer to Gallery ==
	gallery = self.destinationViewController;
	viewer = self.sourceViewController;
    
	// Set the index of the artboard to show so that the render thread can start at the correct index.
	NSInteger selectedIndex = viewer.visibleArtboardIndex;
	[gallery setRenderingStartIndexForSelectedIndex:selectedIndex];
	
    // cause gallery view to load if it hasn't already - this can occur when app automatically navigates to viewer/editor, as in the case of first launch
    [gallery view];

    // if the location was offscreen, scroll the gallery into position for segue. This is necessary in case, for example, the user navigation to the Viewer, paged through many artboards, and stopped at one that was out of view on the original Gallery screen and then wants to go back
	// Inset the rect to work around a bug where the scroll view would be scrolled horizontally in scrollRectToVisible.
	CGRect selectedArtboardRect = CGRectInset([gallery artboardFrameRectForIndex:selectedIndex], 4, 4);
	[gallery.artboardsScrollView scrollRectToVisible:selectedArtboardRect animated:NO];
    
    // hide the frame view so that it is not shown during segue animation
    UIView *frameView = [gallery artboardFrameViewAtIndex:selectedIndex];
    frameView.hidden = YES;
    
	// Gallery is behind everything that moves. 
	//		Taking snapshot of gallery.view takes 1400 to 1500 ms on the first run, and then 1300 to 1375 ms on subsequent runs.)
	//		Taking snapshot of gallery.artboardsScrollView is about the same, but is cut off by the content insets.
	//		After optimizing the drawing code on 2011-12-05, it takes about 160 ms now.
	UIImageView *galleryImageView = [self imageViewOfView:gallery.view withTopLevelView:gallery.view];
	[viewer.view insertSubview:galleryImageView belowSubview:viewer.topToolbar];

    // unhide the frame view 
    frameView.hidden = NO;
    
	// Gallery's top toolbar dissolves in. (This takes 3 to 5 ms.)
	UIImageView *topToolbar = [self imageViewOfView:gallery.topToolbar withTopLevelView:gallery.view];
	topToolbar.alpha = 0.0;
	[viewer.view addSubview:topToolbar];
	
	// Viewer's top toolbar moves up.
	CGRect topToolbarEnd = viewer.topToolbar.frame;
	topToolbarEnd.origin.y -= topToolbarEnd.size.height;
	
	// Artboard shrinks to its position in the grid. (This takes 4 to 10 ms.)

	// Create image views for frame and artboard image
	UIImage *artboardImage = [[gallery.artboards objectAtIndex:selectedIndex] renderedImage];
    UIImageView *artboardImageView = [[UIImageView alloc] initWithImage:artboardImage];
	artboardImageView.layer.magnificationFilter = kCAFilterNearest;
    UIImageView *frameImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"galleryFrameImage"]];
	frameImageView.layer.magnificationFilter = kCAFilterNearest;

	// Update the artboard in the gallery that is being viewed because the image is already rendered.
	[gallery setArtboardImage:artboardImage atIndex:selectedIndex];
	 
	// Starting frame rects
	artboardImageView.frame = CGRectMake(0.0, 40.0, 320.0, 320);
    frameImageView.frame = CGRectInset(artboardImageView.frame, -GallerySegueArtboardEndInset, -GallerySegueArtboardEndInset);

	// Ending frame rects
	CGRect frameEnd = [gallery.view convertRect:[gallery artboardFrameRectForIndex:selectedIndex] fromView:gallery.artboardsScrollView];
	CGRect artboardEnd = CGRectInset(frameEnd, 4.0, 4.0);
	
	// Insert views into current view
	[viewer.view insertSubview:frameImageView belowSubview:viewer.topToolbar];
	[viewer.view insertSubview:artboardImageView belowSubview:viewer.topToolbar];
    	
	// the bottom toolbar slides off-screen
	CGRect toolbarEnd = viewer.bottomToolbarContainer.frame;
	toolbarEnd.origin.y = viewer.view.bounds.size.height;
	
	// Disable UI interaction during animation.
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	[UIView animateWithDuration:SegueOpenArtboardDuration animations:^{
		artboardImageView.frame = artboardEnd;
		frameImageView.frame = frameEnd;
		topToolbar.alpha = 1.0;
		viewer.topToolbar.frame = topToolbarEnd;
		viewer.bottomToolbarContainer.frame = toolbarEnd;
	} completion:^(BOOL finished) {
		[viewer.navigationController popViewControllerAnimated:NO];
		// Remove added subviews.
		[galleryImageView removeFromSuperview];
		[topToolbar removeFromSuperview];
		[artboardImageView removeFromSuperview];
		[frameImageView removeFromSuperview];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
 	
	// == Sound effects ==
	[UIAppDelegate.soundEffects playCloseViewerSound];
}

- (void)perform {
    if ([self.sourceViewController isKindOfClass:[GalleryViewController class]] && [self.destinationViewController isKindOfClass:[ViewerViewController class]]) {
		[self transitionFromGallery:self.sourceViewController toViewer:self.destinationViewController];
    } else if ([self.sourceViewController isKindOfClass:[ViewerViewController class]] && [self.destinationViewController isKindOfClass:[GalleryViewController class]]) {
		[self transitionFromViewer:self.sourceViewController toGallery:self.destinationViewController];
		// TODO: fix reverse transitions
		//[self.destinationViewController.navigationController popViewControllerAnimated:NO];
	}
}

@end
