//
//  ArtboardView.m
//  eboy
//
//  Created by Brian Papa on 8/29/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "ArtboardView.h"
#import "eboyAppDelegate.h"
#import "TileView.h"
#import "Artboard.h"
#import "ArtboardTile.h"
#import "PlacedTile.h"
#import "ColorPalette.h"
#import <QuartzCore/QuartzCore.h>
    
// Constants
NSString *ArtboardTileViewToRotateKey = @"ArtboardTileViewToRotateKey";
NSString *ArtboardNeighborTileViewsKey = @"ArtboardNeighborTileViewsKey";
NSInteger ArtboardTileViewToRotateTag = 102929;
NSTimeInterval ArtboardTileQuickTapSeconds = 0.25;
NSTimeInterval ArtboardTileDragMinDistance = 8.0;


@implementation ArtboardView

- (id)initWithFrame:(CGRect)frame artboard:(Artboard*)anArtboard {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIAppDelegate.artboardBackgroundColor;
        self.opaque = YES;
        self.artboard = anArtboard;
    }
    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	self.backgroundColor = UIAppDelegate.artboardBackgroundColor;
	self.opaque = YES;
}

- (void)drawRect:(CGRect)rect {    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
	const CGFloat kGridLineThickness = 2.0;
	const CGFloat kGridDivisions = 8.0;
			
	// Draw background.
	CGContextSetFillColorWithColor(context, UIAppDelegate.artboardBackgroundColor.CGColor);
	CGContextFillRect(context, self.bounds);
	
	// Draw grid.
	if (self.showGrid) {
		CGFloat unitWidth = self.bounds.size.width / kGridDivisions;
		CGFloat a;
		CGRect horizontalLine = CGRectMake(0.0, 0.0, self.bounds.size.width, kGridLineThickness);
		CGRect verticalLine = CGRectMake(0.0, 0.0, kGridLineThickness, self.bounds.size.height);
		UIBezierPath *gridPath = [UIBezierPath bezierPath];
		
		// Create a path with all the grid lines first, then draw it, which is faster than drawing each rect individually.
		for (a = 1.0; a <= 8.0; a+=1.0) {
			horizontalLine.origin.y = a * unitWidth - kGridLineThickness * 0.5;
			verticalLine.origin.x = a * unitWidth - kGridLineThickness * 0.5;
			[gridPath appendPath:[UIBezierPath bezierPathWithRect:horizontalLine]];
			[gridPath appendPath:[UIBezierPath bezierPathWithRect:verticalLine]];
		}
		CGContextSetFillColorWithColor(context, UIAppDelegate.shadowColor.CGColor);
		[gridPath fill];
	}
	
    // draw the rendered image to this context
	UInt32 shadowColor = [UIAppDelegate colorWithUIColor:UIAppDelegate.shadowColor];
	UIImage *renderedImage = [self.artboard renderedImageWithTileToSkip:self.currentlyMovingTile shadow:YES shadowColor:shadowColor backgroundColor:0];
	CGContextSetInterpolationQuality(context, kCGInterpolationNone);
	[renderedImage drawInRect:self.bounds];
    
    CGContextRestoreGState(context);
}

#pragma mark - Getters

- (CGPoint)centerForGridX:(int)gridX gridY:(int)gridY {
    CGFloat centerX = (gridX * ArtboardTileSize) + (ArtboardTileSize / 2);
    CGFloat centerY = (gridY * ArtboardTileSize) + (ArtboardTileSize / 2);
    return CGPointMake(centerX, centerY);
}

- (NSDictionary*)tileViewsForRotationAtPoint:(CGPoint)point {
    int gridX = point.x / ArtboardTileSize;
    int gridY = point.y / ArtboardTileSize;
    PlacedTile *placedTile = [self.artboard tileAtGridX:gridX gridY:gridY];
    if (!placedTile)
        return nil;

    // mark as "moving" so that it isn't drawn on the next drawRect pass
    self.currentlyMovingTile = placedTile;
    
    // create a tile view for the tile view to rotate
    CGRect tileViewFrame = CGRectMake(gridX * ArtboardTileSize, gridY * ArtboardTileSize, ArtboardTileSize, ArtboardTileSize);
    TileView *tileViewToRotate = [[TileView alloc] initWithFrame:tileViewFrame placedTile:placedTile];
    tileViewToRotate.tag = ArtboardTileViewToRotateTag;
    tileViewToRotate.showsShadow = YES;

    NSMutableDictionary *tileViewsDictionary = [NSMutableDictionary dictionary];
    [tileViewsDictionary setValue:tileViewToRotate forKey:ArtboardTileViewToRotateKey];
    
    // any neighboring tile views
    NSMutableArray *neighbors = [NSMutableArray array];
    [tileViewsDictionary setValue:neighbors forKey:ArtboardNeighborTileViewsKey];
    PlacedTile *adjacentTile = [self.artboard tileAtGridX:gridX + 1 gridY:gridY];
    if (adjacentTile) {
        CGRect adjacentTileViewFrame = CGRectMake((gridX + 1) * ArtboardTileSize, gridY * ArtboardTileSize, ArtboardTileSize, ArtboardTileSize);
        [neighbors addObject:[[TileView alloc] initWithFrame:adjacentTileViewFrame placedTile:adjacentTile]];
    }
    PlacedTile *belowTile = [self.artboard tileAtGridX:gridX gridY:gridY+1];
    if (belowTile) {
        CGRect belowTileViewFrame = CGRectMake(gridX * ArtboardTileSize, (gridY + 1) * ArtboardTileSize, ArtboardTileSize, ArtboardTileSize);
        [neighbors addObject:[[TileView alloc] initWithFrame:belowTileViewFrame placedTile:belowTile]];    
    }
    PlacedTile *diagonalTile = [self.artboard tileAtGridX:gridX+1 gridY:gridY+1];
    if (diagonalTile) {
        CGRect diagonalTileViewFrame = CGRectMake((gridX + 1) * ArtboardTileSize, (gridY + 1) * ArtboardTileSize, ArtboardTileSize, ArtboardTileSize);
        [neighbors addObject:[[TileView alloc] initWithFrame:diagonalTileViewFrame placedTile:diagonalTile]];
    }
    
    return tileViewsDictionary;
}

- (TileView*)tileViewForMovingAtPoint:(CGPoint)point {
    int gridX = point.x / ArtboardTileSize;
    int gridY = point.y / ArtboardTileSize;
    PlacedTile *placedTile = [self.artboard tileAtGridX:gridX gridY:gridY];
    if (!placedTile)
        return nil;
        
    CGRect tileFrame = CGRectMake(gridX * ArtboardTileSize, gridY * ArtboardTileSize, ArtboardTileSize, ArtboardTileSize);
    self.editTileFrame = [NSValue valueWithCGRect:tileFrame];
    
    // The currently moving tile is excluded from drawing.
    self.currentlyMovingTile = placedTile;
    [self redrawArtboardImage];
    
    TileView *tileView = [[TileView alloc] initWithFrame:tileFrame placedTile:placedTile];
    tileView.center = point;
    tileView.showsShadow = YES;
    
    return tileView;
}

- (TileView*)tileViewForArtboardTile:(ArtboardTile*)artboardTile toBeCoveredAtGridPoint:(CGPoint)point withOrientation:(PlacedTileOrientation)orientation {
    int gridX = point.x;
    int gridY = point.y;
    
    CGRect tileFrame = CGRectMake(gridX * ArtboardTileSize, gridY * ArtboardTileSize, ArtboardTileSize, ArtboardTileSize);
    
    TileView *tileView = [[TileView alloc] initWithFrame:tileFrame tile:artboardTile];
    
    // the neighbors are for shadow computation
    PlacedTile* rightNeighbor = [self.artboard tileAtGridX:gridX + 1 gridY:gridY];
    PlacedTile* bottomNeighbor = [self.artboard tileAtGridX:gridX gridY:gridY + 1];
    PlacedTile* bottomRightNeighbor = [self.artboard tileAtGridX:gridX + 1 gridY:gridY + 1];

    // Translate the path built at the end
    CGAffineTransform shadowTransform;
    
    // the orientation determines the orientation of this Tile View
    switch (orientation) {
        case PlacedTileRightSideUp:
            shadowTransform = CGAffineTransformIdentity;
            break;
            
        case PlacedTileOnRightSide:
            tileView.transform = CGAffineTransformMakeRotation(M_PI_2);
            shadowTransform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
            
        case PlacedTileUpsideDown:
            tileView.transform = CGAffineTransformMakeRotation(M_PI);
            shadowTransform = CGAffineTransformMakeRotation(-M_PI);
            break;
            
        case PlacedTileOnLeftSide:
            tileView.transform = CGAffineTransformMakeRotation(3 * M_PI_2);
            shadowTransform = CGAffineTransformMakeRotation(-3 * M_PI_2);
            break;
    }
    
    // build the shadow path based on neighbors
    if (!rightNeighbor || !bottomRightNeighbor || !bottomNeighbor) {
        tileView.layer.shadowColor = [UIAppDelegate shadowColor].CGColor;
        tileView.layer.shadowOpacity = 0.9;
        tileView.layer.shadowRadius = 0.0;
        tileView.layer.shadowOffset = CGSizeMake(0.0, 0.0);

        int shadowOffsetSize = ArtboardTileSize / TileViewShadowSizeFactor;
        
        CGMutablePathRef theShadowPath = CGPathCreateMutable();
        if (!rightNeighbor) {
            CGRect shadowRect = CGRectMake(ArtboardTileSize, shadowOffsetSize, shadowOffsetSize, ArtboardTileSize - shadowOffsetSize);
            CGPathAddRect(theShadowPath, NULL, shadowRect);
        }
        if (!bottomNeighbor) {
            CGRect shadowRect = CGRectMake(shadowOffsetSize, ArtboardTileSize, ArtboardTileSize - shadowOffsetSize, shadowOffsetSize);
            CGPathAddRect(theShadowPath, NULL, shadowRect);
        } 
        if (!bottomRightNeighbor) {
            CGRect shadowRect = CGRectMake(ArtboardTileSize, ArtboardTileSize, shadowOffsetSize, shadowOffsetSize);
            CGPathAddRect(theShadowPath, NULL, shadowRect);
        }
        
        // translate to origin and rotate
        CGAffineTransform translation = CGAffineTransformMakeTranslation(-ArtboardTileSize/2, -ArtboardTileSize/2);
        CGAffineTransform originTransform = CGAffineTransformConcat(translation, shadowTransform);
        CGAffineTransform translateBack = CGAffineTransformMakeTranslation(ArtboardTileSize/2, ArtboardTileSize/2);
        CGAffineTransform pathTransform = CGAffineTransformConcat(originTransform, translateBack);
        CGPathRef transformedShadowPath = CGPathCreateCopyByTransformingPath(theShadowPath, &pathTransform);
        
        tileView.layer.shadowPath = transformedShadowPath;
        
        CGPathRelease(theShadowPath);
        CGPathRelease(transformedShadowPath);
    }        
    return tileView;
}

#pragma mark - Image Rendering


- (UIImage *)resizeImage:(UIImage *)sourceImage withZoom:(CGFloat)zoom {
	UIImage *result = nil;
	CGImageRef cgImage = nil;
	int bitmapWidth = floor (sourceImage.size.width * zoom);
	int bitmapHeight = floor (sourceImage.size.height * zoom);
	
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(nil, bitmapWidth, bitmapHeight, 8, bitmapWidth * 4, colorspace, kCGImageAlphaPremultipliedLast);
	if (context != nil) {
		CGImageRef resultImage = [sourceImage CGImage];
		CGContextSetInterpolationQuality(context, kCGInterpolationNone);
		CGRect drawRect = CGRectMake(0, 0, bitmapWidth, bitmapHeight);
		CGContextDrawImage(context, drawRect, resultImage);
		
		cgImage = CGBitmapContextCreateImage (context);
		CGContextRelease(context);
	}
	CGColorSpaceRelease(colorspace);
	result = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return result;
}

- (void)redrawArtboardImage {
	[self setNeedsDisplay];
	//self.artboardImageLayer.contents = [self renderedImage];
}

- (UIImage*)renderedImageWithScaleFactor:(CGFloat)scaleFactor {
	UIImage *image = [self.artboard renderedImage];
	return [self resizeImage:image withZoom:scaleFactor];
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	// One-finger touches can either be to move a tile or to rotate a tile.
	// To decide whether the user meant to tap to rotate or drag to move a tile, we have to consider how far the touch moved and the duration from begin to end of touch.
	//NSLog(@"Touches began.");
	if (self.touchPhaseChangedHandler) {
		self.touchPhaseChangedHandler(UITouchPhaseBegan);
	}
	if (touches.count == 1) {
		
		UITouch *anyTouch = [touches anyObject];
		self.touchBeganTimestamp = anyTouch.timestamp;
		self.touchStartPoint = [anyTouch locationInView:self];
		self.touchDragStartTimer = [NSTimer scheduledTimerWithTimeInterval:ArtboardTileQuickTapSeconds target:self selector:@selector(startTileDragWithTimer:) userInfo:touches repeats:NO];
	} else {
		[self cancelTileDragWithTouches:touches];
	}
	if (self.maximumTouchCount < touches.count) {
		self.maximumTouchCount = touches.count;
	}
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	//NSLog(@"Touches moved.");
	if (self.touchPhaseChangedHandler) {
		self.touchPhaseChangedHandler(UITouchPhaseMoved);
	}
	if (self.maximumTouchCount == 1) {
		if (!self.isDraggingTile) {
			UITouch *anyTouch = [touches anyObject];
			CGPoint movePoint = [anyTouch locationInView:self];
			CGFloat distance = hypot(movePoint.x - self.touchStartPoint.x, movePoint.y - self.touchStartPoint.y);
			if (distance >= ArtboardTileDragMinDistance) {
				[self startTileDragWithTouches:touches];
			}
		}
		if (self.isDraggingTile) {
			[self movedTileDragWithTouches:touches];
		}
	}
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	//NSLog(@"Touches ended.");
	if (self.touchPhaseChangedHandler) {
		self.touchPhaseChangedHandler(UITouchPhaseEnded);
	}
	[self endTileDragWithTouches:touches];
	if (touches.count == 1 && self.maximumTouchCount == 1) {
		// Only consider it a "tap" if user didn't move too far from beginning point, used only one finger, and user didn't hold down for more than 0.25 seconds.
		UITouch *anyTouch = [touches anyObject];
		CGPoint endTouchPoint = [anyTouch locationInView:self];
		CGFloat distance = hypot(endTouchPoint.x - self.touchStartPoint.x, endTouchPoint.y - self.touchStartPoint.y);
		BOOL isQuickTap = (anyTouch.timestamp < self.touchBeganTimestamp + ArtboardTileQuickTapSeconds);
	
		if (distance < ArtboardTileDragMinDistance && isQuickTap) {
			if (self.tileTapHandler) {
				self.tileTapHandler([touches anyObject]);
			}
		}
	}
	self.touchBeganTimestamp = 0;
	self.maximumTouchCount = 0;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	//NSLog(@"Touches cancelled.");
	if (self.touchPhaseChangedHandler) {
		self.touchPhaseChangedHandler(UITouchPhaseEnded);
	}
	[self cancelTileDragWithTouches:touches];
	self.touchBeganTimestamp = 0;
	self.maximumTouchCount = 0;
}

- (void)startTileDragWithTimer:(NSTimer *)timer {
	NSSet *touches = [timer userInfo];
	[self startTileDragWithTouches:touches];
}

- (void)startTileDragWithTouches:(NSSet<UITouch *> *)touches {
	//NSLog(@"Start tile drag.");
	UITouch *anyTouch = [touches anyObject];
	self.isDraggingTile = YES;
	if (self.tileDragHandler) {
		self.tileDragHandler(anyTouch, UIGestureRecognizerStateBegan);
	}
	[self.touchDragStartTimer invalidate];
	self.touchDragStartTimer = nil;
}

- (void)movedTileDragWithTouches:(NSSet<UITouch *> *)touches {
	//NSLog(@"Move tile drag.");
	UITouch *anyTouch = [touches anyObject];
	if (self.isDraggingTile) {
		if (self.tileDragHandler) {
			self.tileDragHandler(anyTouch, UIGestureRecognizerStateChanged);
		}
	}
	[self.touchDragStartTimer invalidate];
	self.touchDragStartTimer = nil;
}

- (void)endTileDragWithTouches:(NSSet<UITouch *> *)touches {
	UITouch *anyTouch = [touches anyObject];
	[self.touchDragStartTimer invalidate];
	self.touchDragStartTimer = nil;
	if (self.isDraggingTile) {
		//NSLog(@"End tile drag.");
		self.isDraggingTile = NO;
		if (self.tileDragHandler) {
			self.tileDragHandler(anyTouch, UIGestureRecognizerStateEnded);
		}
	}
}

- (void)cancelTileDragWithTouches:(NSSet<UITouch *> *)touches {
	NSLog(@"Cancel tile drag.");
	UITouch *anyTouch = [touches anyObject];
	[self.touchDragStartTimer invalidate];
	self.touchDragStartTimer = nil;
	if (self.isDraggingTile) {
		self.isDraggingTile = NO;
		if (self.tileDragHandler) {
			self.tileDragHandler(anyTouch, UIGestureRecognizerStateCancelled);
		}
	}
}

@end
