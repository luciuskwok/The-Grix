//
//  ArtboardStoryboardSegue.h
//  eboy
//
//  Created by Brian Papa on 10/3/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Artboard;

@interface ArtboardStoryboardSegue : UIStoryboardSegue

- (UIImageView *)imageViewOfView:(UIView *)view withTopLevelView:(UIView *)topView;

@end
