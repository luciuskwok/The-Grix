//
//  TileView.m
//  eboy
//
//  Created by Brian Papa on 8/15/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "TileView.h"
#import "ColorPalette.h"
#import "eboyAppDelegate.h"
#import "ArtboardView.h"
#import "ArtboardTile.h"
#import "ArtboardTilePalette.h"
#import "Artboard.h"
#import "PlacedTile.h"
#import <QuartzCore/CoreAnimation.h>

NSInteger TileViewShadowSizeFactor = 4;

@implementation TileView

- (id)initWithFrame:(CGRect)frame placedTile:(PlacedTile *)aTile {
    self = [self initWithFrame:frame tile:aTile.tile];
    if (self) {
        self.placedTile = aTile;
        self.layer.transform = CATransform3DMakeRotation(-self.placedTile.rotationAngle, 0, 0, 1);
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame tile:(ArtboardTile*)aTile {
    self = [super initWithFrame:frame];
    if (self) {
        self.artboardTile = aTile;
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
    }
    return self;
}

- (void)flipCurrentContextForRect:(CGRect)rect {
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(currentContext, 0.0, rect.size.height);
    CGContextScaleCTM(currentContext, 1.0, -1.0);
}

- (UIImage *)renderedImage {
	// Create a UIImage of the artboard with shadow and background.
	UIImage *result = nil;
	CGImageRef cgImage = nil;
	const NSInteger tileWidth = 8;
	const NSInteger tileHeight = 8;

	// Get the color lookup table.
	const NSData *clutData = [self.artboardTile.tilePalette.artboard.unsavedColorPalette colorLookupTable];
	if (clutData == nil) 
		return nil;
	const UInt32 *clut = [clutData bytes];
	const NSInteger clutCount = clutData.length / sizeof(UInt32);
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	
	// Get tile pixel data.
	NSData *tilePixelData = [self.artboardTile pixelData];
	if (tilePixelData.length != 64) {
        CGColorSpaceRelease(colorspace);
		return nil;
    }
	
	// Create bitmap context data.
	NSMutableData *bitmapContextData = [NSMutableData dataWithLength: tileWidth * tileHeight * 4];
	if (bitmapContextData != nil) {
		UInt32 *bitmapContext = [bitmapContextData mutableBytes];
		const UInt8 *tilePixelPtr = [tilePixelData bytes];
		NSInteger tileX, tileY, tileIndex;
		UInt32 pixelRGBAValue;
		for (tileY = 0; tileY < tileHeight; tileY++) {
			for (tileX = 0; tileX < tileWidth; tileX++) {
				tileIndex = tileX + tileY * tileWidth;
				
				// Bounds check.
				if (tileX >= 0 && tileX < tileWidth && tileY >= 0 && tileY < tileHeight) {
					UInt8 pixelIndexValue = tilePixelPtr[tileIndex];
					pixelRGBAValue = (pixelIndexValue < clutCount) ? clut[pixelIndexValue] : 0;
					
					// Set the pixel RGBA value in the bitmap.
					bitmapContext[tileIndex] = pixelRGBAValue;
				}
			}
		}
		
		// Create a bitmap context with the image data
		CGContextRef context = CGBitmapContextCreate(bitmapContext, tileWidth, tileHeight, 8, tileWidth * 4, colorspace, kCGImageAlphaPremultipliedLast);
		if (context != nil) {
			cgImage = CGBitmapContextCreateImage (context);
			CGContextRelease(context);
		}
	}
	CGColorSpaceRelease(colorspace);
	result = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return result;
}

- (void)drawRect:(CGRect)rect {    
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw image 
	CGContextSetInterpolationQuality(context, kCGInterpolationNone);
	UIImage *image = [self renderedImage];
	[image drawInRect:self.bounds];
}

- (void)returnToTileboardCompletion:(void (^)(BOOL finished))completion {    
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformIdentity;
        self.center = self.initialCenter;
    } completion:completion];        
}

- (void)deleteTile {
    [self removeFromSuperview];
}

- (void)grab {    
    // scale tile
    [UIView animateWithDuration:0.25 animations:^{
        CGAffineTransform rotateTransform = CGAffineTransformMakeRotation(-self.placedTile.rotationAngle);
        CGAffineTransform scaleTransform =CGAffineTransformMakeScale(ArtboardTileDragAndRotateScaleFactor, ArtboardTileDragAndRotateScaleFactor);
        self.transform = CGAffineTransformConcat(rotateTransform, scaleTransform); 
    }];
    
    self.showsShadow = NO;
}

- (void)setShowsShadow:(BOOL)shouldShow {
    _showsShadow = shouldShow;
    
    // Draw shadow behind tile if it is a placed tile
    if (self.placedTile) {
        if (_showsShadow) {
            self.layer.shadowColor = [UIAppDelegate shadowColor].CGColor;
            self.layer.shadowOpacity = 0.9;
            self.layer.shadowRadius = 0.0;
            
            // shadow offset depends on current orientation of view
            float offsetWidth;
            float offsetHeight;
            if (self.placedTile.orientation == PlacedTileRightSideUp) {
                offsetWidth = self.frame.size.width / TileViewShadowSizeFactor;
                offsetHeight = self.frame.size.height / TileViewShadowSizeFactor;
            } else if (self.placedTile.orientation == PlacedTileOnRightSide) {
                offsetWidth = self.frame.size.width / TileViewShadowSizeFactor;
                offsetHeight = -self.frame.size.height / TileViewShadowSizeFactor;
            } else if (self.placedTile.orientation == PlacedTileUpsideDown) {
                offsetWidth = -self.frame.size.width / TileViewShadowSizeFactor;
                offsetHeight = -self.frame.size.height / TileViewShadowSizeFactor;
            } else {
                offsetWidth = -self.frame.size.width / TileViewShadowSizeFactor;
                offsetHeight = self.frame.size.height / TileViewShadowSizeFactor;
            }
            self.layer.shadowOffset = CGSizeMake(offsetWidth, offsetHeight);
        } else {
            // since there is no way to turn shadow "off", just move it "behind" tile
            self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        }
    }
}

- (NSInteger)gridX {
    return (NSInteger)self.center.x / (NSInteger)self.bounds.size.width;
}

- (NSInteger)gridY {
    return (NSInteger)self.center.y / (NSInteger)self.bounds.size.height;
}

- (NSInteger)gridIndex {
    return (self.gridY * ArtboardTileGridSize) + self.gridX;
}

@end
