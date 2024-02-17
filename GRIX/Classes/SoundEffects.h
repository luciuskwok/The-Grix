//
//  SoundEffect.h
//  eboy
//
//  Created by Lucius Kwok on 12/3/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SoundEffects : NSObject
{
	SystemSoundID silenceSound;
	SystemSoundID appIntroSound;
	SystemSoundID artboardDeleteSound;
	SystemSoundID changeColorSound;
	SystemSoundID colorPaletteSwipeSound;
	SystemSoundID drawerOpenSound;
	SystemSoundID lockSound;
	SystemSoundID paintSound[4];
	SystemSoundID selectColorSound;
	SystemSoundID slideDialogSound;
	SystemSoundID tileDropSound;
	SystemSoundID tilePaletteClickSound;
	SystemSoundID tilePlaceSound[2];
	SystemSoundID tileRotateSound;
	SystemSoundID unlockSound;
	SystemSoundID zoomInDoubleSound;
	SystemSoundID zoomInSound;
	SystemSoundID zoomOutSound;
}

+ (BOOL)soundEffectsEnabled;

- (SystemSoundID)createSoundWithName:(NSString *)name;

- (void)playSilence;
- (void)playAppIntroSound;
- (void)playUnlockSound;
- (void)playLockSound;
- (void)playOpenTileEditorSound;
- (void)playCloseTileEditorSound;
- (void)playColorPaletteClickSound;
- (void)playTilePaletteClickSound;
- (void)playDeleteArtboardSound;
- (void)playDuplicateArtboardSound;
- (void)playOpenViewerSound;
- (void)playCloseViewerSound;
- (void)playOpenSheetSound;
- (void)playCloseSheetSound;
- (void)playDrawerOpenCloseSound;
- (void)playTilePlaceSoundAtX:(int)x y:(int)y;
- (void)playTileRotationSound;
- (void)playTileRotationStartedSoundWithTapCount:(int)tapCount;
- (void)playTileDroppedSound;
- (void)playSelectColorSound;
- (void)playChangeColorSound;
- (void)playPaintSoundAtX:(int)x y:(int)y;

@end
