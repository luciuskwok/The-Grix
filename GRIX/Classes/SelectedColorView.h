//
//  SelectedColorView.h
//  eboy
//
//  Created by Brian Papa on 8/12/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _SelectedColorViewStyle {
    SelectedColorViewStyleCentered              = 0,
    SelectedColorViewStyleLeftEdge              = 1,
    SelectedColorViewStyleRightEdge             = 2
} SelectedColorViewStyle;

@interface SelectedColorView : UIView

@property (strong, nonatomic) UIColor *color;
@property (assign) SelectedColorViewStyle style;

-(id)initWithFrame:(CGRect)frame color:(UIColor*)aColor style:(SelectedColorViewStyle)style;

@end
