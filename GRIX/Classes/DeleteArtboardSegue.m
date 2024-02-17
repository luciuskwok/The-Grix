//
//  DeleteArtboardSegue.m
//  eboy
//
//  Created by Brian Papa on 10/11/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "DeleteArtboardSegue.h"
#import "GalleryViewController.h"
#import "ViewerViewController.h"
#import "GalleryAndViewerSegue.h"
#import "ArtboardView.h"
#import "eboyAppDelegate.h"
#import "GalleryArtboardFrame.h"
#import <QuartzCore/QuartzCore.h>

@implementation DeleteArtboardSegue

static const CGFloat kDeleteSegueDuration = 0.5;

- (void)perform {
    GalleryViewController *gallery = self.destinationViewController;
    ViewerViewController *viewer = self.sourceViewController;
	
	// Set the index of the artboard to show so that the render thread can start at the correct index.
	NSInteger selectedIndex = viewer.visibleArtboardIndex;
	[gallery setRenderingStartIndexForSelectedIndex:selectedIndex];
	
	// Cause gallery view to load.
	[gallery view];
	
	// Adjust for iPhone 5 screen.
	BOOL tallScreen = viewer.view.bounds.size.height > 480.0;
	
	// Disable UI interaction during animation.
	viewer.artboardsScrollView.userInteractionEnabled = NO;
	    
    // Scroll gallery to show artboard to delete, then remove it so that it doesn't appear in gallery snapshot.
	UIView *frameView = [gallery artboardFrameViewAtIndex:selectedIndex];
    [gallery.artboardsScrollView scrollRectToVisible:CGRectInset(frameView.frame, 4, 4) animated:NO];
	frameView.hidden = YES;
    
	// Place gallery image behind image of artboard.
	UIImageView *galleryImageView = [self imageViewOfView:gallery.view withTopLevelView:gallery.view];
	[viewer.view insertSubview:galleryImageView belowSubview:viewer.topToolbar];
 
	// Artboard and its frame shrink into place
	UIImageView *artboardImageView = [self imageViewOfView:viewer.visibleArtboardView withTopLevelView:viewer.view];
    UIImageView *frameImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"galleryFrameImage"]];
	frameImageView.layer.magnificationFilter = kCAFilterNearest;
	artboardImageView.frame = CGRectMake(0.0, tallScreen? 120.0: 40.0, 320.0, 320);
    frameImageView.frame = CGRectMake(-20.0, tallScreen? 100.0: 20.0, 360.0, 360.0);
    
   // destination for artboard as it's scaled into place back in the gallery
	CGRect galleryFrameFrame = [gallery.view convertRect:frameView.frame fromView:gallery.artboardsScrollView];
    CGRect artboardFrameEnd = CGRectInset(galleryFrameFrame, galleryFrameFrame.size.width / 4, galleryFrameFrame.size.height / 4);
	CGRect artboardEnd = CGRectInset (artboardFrameEnd, 2.0, 2.0);
	[viewer.view insertSubview:frameImageView belowSubview:viewer.bottomToolbarContainer];
	[viewer.view insertSubview:artboardImageView belowSubview:viewer.bottomToolbarContainer];
	
	// the bottom toolbar slides off-screen
	CGRect toolbarEnd = viewer.bottomToolbarContainer.frame;
	toolbarEnd.origin.y = viewer.view.bounds.size.height;
	
    // Schedule animations.
	[UIView animateWithDuration:kDeleteSegueDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
		frameImageView.frame = artboardFrameEnd;
		artboardImageView.frame = artboardEnd;
	} completion:^(BOOL finished) {
		[frameImageView removeFromSuperview];
		[artboardImageView removeFromSuperview];
	}];

	[UIView animateWithDuration:kDeleteSegueDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
		viewer.topToolbar.alpha = 0.0;
		viewer.bottomToolbarContainer.frame = toolbarEnd;
	} completion:^(BOOL finished) {
		[viewer.navigationController popViewControllerAnimated:NO];
		// Remove added subviews.
		[galleryImageView removeFromSuperview];
		viewer.artboardsScrollView.userInteractionEnabled = YES;
        
		// Finish up the animation in the gallery view controller. The actual deleting of the artboard happens in the gallery's method, so that the animation works correctly even if the gallery was not loaded before the delete segue started.
		[gallery deleteArtboardAtIndex:selectedIndex];
	}];

	// Sound effects
	[UIAppDelegate.soundEffects playDeleteArtboardSound];
}

@end
