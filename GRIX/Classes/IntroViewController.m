//
//  IntroViewController.m
//  eboy
//
//  Created by Lucius Kwok on 1/24/12.
//  Copyright (c) 2012 Felt Tip Inc. All rights reserved.
//

#import "IntroViewController.h"
#import "eboyAppDelegate.h"
#import "UIView+Setup.h"

const NSTimeInterval kAnimationStepDuration = 1/12.0; // 12 fps

@implementation IntroViewController

- (id)init
{
    self = [super initWithNibName:@"IntroView" bundle:nil];
    if (self) {
		// Cause sound effects to load and play a quiet sound to prime the buffers.
		[UIAppDelegate.soundEffects playSilence];
    }
    return self;
}

- (void)close {
	if ([self.navigationController.visibleViewController isEqual:self]) 
		[self.navigationController popViewControllerAnimated:NO];
	else
		[self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self.view setupSubviewsToBePixelatedAndExclusiveTouch];

	// Hide lit versions of words
	self.wordTheView.alpha = 0.0;
	self.wordGrixView.alpha = 0.0;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	// == Icon animation begin ==
	// Animation 1: Rotate icon 90 degrees.
	[UIView animateWithDuration:kAnimationStepDuration * 2 animations:^(void) {
		CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
		self.iconView.transform = transform;
		self.iconShadowView.transform = transform;
	} completion:^(BOOL finished) {
		// Sound effect
		[UIAppDelegate.soundEffects playTileRotationSound];
		
		// Animation 2: Rotate icon 180 degrees.
		[UIView animateWithDuration:kAnimationStepDuration * 2 delay:kAnimationStepDuration options:0 animations:^(void) {
			CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI);
			self.iconView.transform = transform;
			self.iconShadowView.transform = transform;
		} completion:^(BOOL finished) {
			// Sound effect
			[UIAppDelegate.soundEffects playTileRotationSound];

			// Animation 3: Rotate icon 270 degrees
			[UIView animateWithDuration:kAnimationStepDuration * 2 delay:kAnimationStepDuration options:0 animations:^(void) {
				CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
				self.iconView.transform = transform;
				self.iconShadowView.transform = transform;
			} completion:^(BOOL finished) {
				// Sound effect
				[UIAppDelegate.soundEffects playTileRotationSound];

				// Animation 4: Rotate icon back to normal.
				[UIView animateWithDuration:kAnimationStepDuration * 2 delay:kAnimationStepDuration options:0 animations:^(void) {
					CGAffineTransform transform = CGAffineTransformMakeRotation(0);
					self.iconView.transform = transform;
					self.iconShadowView.transform = transform;
				} completion:^(BOOL finished) {
					// Sound effect
					[UIAppDelegate.soundEffects playTileRotationSound];
				}]; // Close Animation 4.
			}]; // Close Animation 3.
		}]; // Close Animation 2.
	}]; // Close Animation 1.
	// == Icon animation end ==
	
	// == Title animation begin ==
	// Animation 1: Turn on "THE".
	[UIView animateWithDuration:0 delay:kAnimationStepDuration * 2 options:0 animations:^(void) {
		self.wordTheView.alpha = 1.0;
	} completion:^(BOOL finished) {
		// Animation 2: Turn off "THE".
		[UIView animateWithDuration:0 delay:kAnimationStepDuration options:0 animations:^(void) {
			self.wordTheView.alpha = 0.0;
		} completion:^(BOOL finished) {
			// Animation 3: Turn on "GRIX".
			[UIView animateWithDuration:0 delay:kAnimationStepDuration * 2 options:0 animations:^(void) {
				self.wordGrixView.alpha = 1.0;
			} completion:^(BOOL finished) {
				// Animation 4: Turn off "GRIX".
				[UIView animateWithDuration:0 delay:kAnimationStepDuration options:0 animations:^(void) {
					self.wordGrixView.alpha = 0.0;
				} completion:^(BOOL finished) {
					// Animation 5: Turn on both words.
					[UIView animateWithDuration:0 delay:kAnimationStepDuration * 2 options:0 animations:^(void) {
						self.wordTheView.alpha = 1.0;
						self.wordGrixView.alpha = 1.0;
					} completion:^(BOOL finished) {
						// Animation 6: Turn off both words.
						[UIView animateWithDuration:0 delay:kAnimationStepDuration options:0 animations:^(void) {
							self.wordTheView.alpha = 0.0;
							self.wordGrixView.alpha = 0.0;
						} completion:^(BOOL finished) {
							// Animation 7: Turn on both words.
							[UIView animateWithDuration:0 delay:kAnimationStepDuration * 2 options:0 animations:^(void) {
								self.wordTheView.alpha = 1.0;
								self.wordGrixView.alpha = 1.0;
							} completion:^(BOOL finished) {
								
							}]; // Close Animation 7.
						}]; // Close Animation 6.
					}]; // Close Animation 5.
				}]; // Close Animation 4.
			}]; // Close Animation 3.
		}]; // Close Animation 2.
	}]; // Close Animation 1.
	// == Title animation end ==

	// Auto-dismiss.
	[self performSelector:@selector(close) withObject:nil afterDelay:kAnimationStepDuration * 12.0 + 0.5];
}

@end
