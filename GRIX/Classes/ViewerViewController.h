//
//  ViewerViewController.h
//  eboy
//
//  Created by Brian Papa on 8/6/11.
//  Copyright 2011 Felt Tip Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Artboard,ArtboardView;
@protocol AccountLoginFormViewControllerDelegate, ShareFormViewControllerDelegate;

@interface ViewerViewController : UIViewController
<UIDocumentInteractionControllerDelegate>

@property (readonly) ArtboardView* visibleArtboardView;
@property (strong, nonatomic) IBOutlet UIScrollView *artboardsScrollView;
@property (strong, nonatomic) NSMutableArray *artboards;
@property (assign) NSInteger artboardsCount;
@property (assign) NSInteger visibleArtboardIndex;
@property (strong, nonatomic) IBOutlet UIView *bottomToolbarContainer;
@property (strong, nonatomic) UIDocumentInteractionController *documentInteractionController;
@property (strong, nonatomic) IBOutlet UIView *deleteImageActionSheetView;
@property (strong, nonatomic) IBOutlet UIButton *deleteSheetDeleteButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteSheetCancelButton;
@property (strong, nonatomic) IBOutlet UIView *tileboardView;
@property (strong, nonatomic) IBOutlet UIButton *galleryButton;
@property (strong, nonatomic) IBOutlet UIButton *lockButton;
@property (strong, nonatomic) IBOutlet UIButton *trashButton;
@property (strong, nonatomic) IBOutlet UIButton *duplicateButton;
@property (strong, nonatomic) IBOutlet UIButton *actionButton;
@property (strong, nonatomic) IBOutlet UIView *topToolbar;
@property (strong, nonatomic) IBOutlet 	UIView *screenDimmerOverlayView;
@property (strong, nonatomic) IBOutlet 	UIActivityIndicatorView *screenDimmerSpinner;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (assign) BOOL isDescendingOrder;

- (IBAction)back:(id)sender;
- (IBAction)showShareSheet:(id)sender;
- (IBAction)showDeleteSheet:(id)sender;
- (IBAction)duplicate:(id)sender;
- (IBAction)edit:(id)sender;

- (IBAction)confirmDeleteImage:(id)sender;
- (IBAction)cancelDeleteImage:(id)sender;

- (void)restoreLevelWithSelectionArray:(NSArray *)selectionArray;

@end
