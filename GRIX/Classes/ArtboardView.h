//
//  ArtboardView.h
//  eboy
//
//  Created by Brian Papa on 8/29/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TileView.h"
#import "PlacedTile.h"

// Constants
UIKIT_EXTERN NSString *ArtboardTileViewToRotateKey;
UIKIT_EXTERN NSString *ArtboardNeighborTileViewsKey;
UIKIT_EXTERN NSInteger ArtboardTileViewToRotateTag;

@class Artboard, TileView, ArtboardContentLayerDelegate;

@interface ArtboardView : UIView

@property (strong, nonatomic) Artboard *artboard;
@property (strong) NSValue *editTileFrame;
@property (assign) BOOL showGrid;
@property (strong, nonatomic) PlacedTile *currentlyMovingTile;

@property (copy, nonatomic) void (^touchPhaseChangedHandler)(UITouchPhase phase);
@property (copy, nonatomic) void (^tileTapHandler)(UITouch *aTouch);
@property (copy, nonatomic) void (^tileDragHandler)(UITouch *aTouch, UIGestureRecognizerState state);
@property (assign, nonatomic) NSTimeInterval touchBeganTimestamp;
@property (assign, nonatomic) NSInteger maximumTouchCount;
@property (assign, nonatomic) CGPoint touchStartPoint;
@property (strong, nonatomic) NSTimer *touchDragStartTimer;
@property (assign, nonatomic) BOOL isDraggingTile;


- (id)initWithFrame:(CGRect)frame artboard:(Artboard*)anArtboard;
- (CGPoint)centerForGridX:(int)gridX gridY:(int)gridY;
- (NSDictionary*)tileViewsForRotationAtPoint:(CGPoint)point;
- (TileView*)tileViewForMovingAtPoint:(CGPoint)point;
- (TileView*)tileViewForArtboardTile:(ArtboardTile*)artboardTile toBeCoveredAtGridPoint:(CGPoint)point withOrientation:(PlacedTileOrientation)orientation;

- (UIImage *)resizeImage:(UIImage *)sourceImage withZoom:(CGFloat)zoom;
- (void)redrawArtboardImage;
- (UIImage*)renderedImageWithScaleFactor:(CGFloat)scaleFactor;

@end

