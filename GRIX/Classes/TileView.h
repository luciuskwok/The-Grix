//
//  TileView.h
//  eboy
//
//  Created by Brian Papa on 8/15/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSInteger TileViewShadowSizeFactor;

@class Tile, PlacedTile, ArtboardTile;

@interface TileView : UIView <UIGestureRecognizerDelegate>

@property (assign) CGPoint initialCenter;
@property (strong, nonatomic) ArtboardTile* artboardTile;
@property (strong, nonatomic) PlacedTile *placedTile;
@property (assign, nonatomic) BOOL showsShadow;
@property (readonly) NSInteger gridX;
@property (readonly) NSInteger gridY;
@property (readonly) NSInteger gridIndex;

- (id)initWithFrame:(CGRect)frame placedTile:(PlacedTile*)aTile;
- (id)initWithFrame:(CGRect)frame tile:(ArtboardTile*)aTile;
- (UIImage *)renderedImage;
- (void)returnToTileboardCompletion:(void (^)(BOOL finished))completion;
- (void)deleteTile;
- (void)grab;

@end
