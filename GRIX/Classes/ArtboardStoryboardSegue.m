//
//  ArtboardStoryboardSegue.m
//  eboy
//
//  Created by Brian Papa on 10/3/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "ArtboardStoryboardSegue.h"
#import "GalleryViewController.h"
#import "ArtboardTilePalette.h"
#import "ArtboardView.h"
#import "Artboard.h"
#import "eboyAppDelegate.h"
#import "ArtboardViewController.h"
#import "ViewerViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation ArtboardStoryboardSegue
    

- (UIImageView *)imageViewOfView:(UIView *)view withTopLevelView:(UIView *)topView {
	if (view == nil) {
		NSLog (@"-[imageViewOfView:withTopLevelView:] was passed a nil view.");
		return nil;
	}
	CGSize imageSize = view.frame.size;
	UIGraphicsBeginImageContextWithOptions(imageSize, YES, 1.0);
	CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorRef backgroundColor = CGColorRetain(([[UIAppDelegate artboardBackgroundColor] CGColor]));
	CGContextSetFillColorWithColor(context, backgroundColor);
    CGColorRelease(backgroundColor);
	CGContextFillRect(context, CGRectMake(0.0, 0.0, imageSize.width, imageSize.height));
	
	// Adjust for content offset in scroll views.
	if ([view isKindOfClass:[UIScrollView class]]) {
		UIScrollView *scrollView = (UIScrollView *)view;
		CGContextTranslateCTM(context, -scrollView.contentOffset.x, -scrollView.contentOffset.y);
	}
	
	[view.layer renderInContext:context];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	// Set up Image View
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	imageView.frame = [view convertRect:view.bounds toView:topView];
	imageView.layer.magnificationFilter = kCAFilterNearest;
	imageView.layer.minificationFilter = kCAFilterNearest;
	return imageView;
}

@end
