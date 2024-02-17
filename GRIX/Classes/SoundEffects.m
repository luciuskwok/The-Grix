//
//  SoundEffect.m
//  eboy
//
//  Created by Lucius Kwok on 12/3/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//
/*
	Notes:
	* AudioServicesPlaySystemSound() can only play short sound files with no changes.
	* AVAudioPlayer lets you play any sound file with adjustable playback rate, like how Podcasts can be sped up, but does not change the pitch of the audio.
	* OpenAL only lets you control the pitch and gain of the audio, and does not allow for other effects. However, you can pre-process the audio buffer since you have access to the raw PCM audio data.
 */

#import "SoundEffects.h"
#import "eboyAppDelegate.h"
#import <AVFoundation/AVFoundation.h>


@implementation SoundEffects

+ (BOOL)soundEffectsEnabled {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:@"soundEffects"] == nil)
		return YES;
	return ([defaults boolForKey:@"soundEffects"]);
}

- (id)init {
	if (self = [super init]) {
		
		// == AudioServices ==
		silenceSound = [self createSoundWithName:@"silence"];
		appIntroSound = [self createSoundWithName:@"app-intro"];
		artboardDeleteSound = [self createSoundWithName:@"artboard-delete"];
		changeColorSound = [self createSoundWithName:@"change-color"];
		colorPaletteSwipeSound = [self createSoundWithName:@"color-palette-swipe"];
		drawerOpenSound = [self createSoundWithName:@"drawer-open-close"];
		lockSound = [self createSoundWithName:@"lock"];
		paintSound[0] = [self createSoundWithName:@"paint-A"];
		paintSound[1] = [self createSoundWithName:@"paint-B"];
		paintSound[2] = [self createSoundWithName:@"paint-C"];
		paintSound[3] = [self createSoundWithName:@"paint-D"];
		selectColorSound = [self createSoundWithName:@"select-color"];
		slideDialogSound = [self createSoundWithName:@"slide-dialog"];
		tileDropSound = [self createSoundWithName:@"tile-drop"];
		tilePaletteClickSound = [self createSoundWithName:@"tile-palette-click"];
		tilePlaceSound[0] = [self createSoundWithName:@"tile-place-A"];
		tilePlaceSound[1] = [self createSoundWithName:@"tile-place-B"];
		tileRotateSound = [self createSoundWithName:@"tile-rotate"];
		unlockSound = [self createSoundWithName:@"unlock"];
		zoomInDoubleSound = [self createSoundWithName:@"zoom-in-double"];
		zoomInSound = [self createSoundWithName:@"zoom-in"];
		zoomOutSound = [self createSoundWithName:@"zoom-out"];
		
		// == AudioSession ==
		AVAudioSession *audioSession = [AVAudioSession sharedInstance];
		NSError *error = nil;
		
		// According to the docs:
		// == kAudioSessionCategory_AmbientSound ==
		// For an app in which sound playback is nonprimary—that is, your app can be used successfully with the sound turned off.
		// This category is also appropriate for “play along” style apps, such as a virtual piano that a user plays over iPod audio. When you use this category, audio from other apps mixes with your audio. Your audio is silenced by screen locking and by the Silent switch (called the Ring/Silent switch on iPhone).
		if (![audioSession setCategory:AVAudioSessionCategoryAmbient error:&error]) {
			if (error) NSLog(@"-[AVAudioSession setCategory:] error: %@", error);
		}
		
		// Activate the audio session.
		if (![audioSession setActive:YES error:&error]) {
			if (error) NSLog(@"-[AVAudioSession audioSession] error: %@", error);
		}
		
	}
	return self;
}

- (void)dealloc {
	// Dectivate the audio session.
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	NSError *error = nil;
	if (![audioSession setActive:NO error:nil]) {
		if (error) NSLog(@"AVAudioSession error: %@", error);
	}
}

- (SystemSoundID)createSoundWithName:(NSString *)name {
	SystemSoundID soundID = -1;
	NSURL *url = [[NSBundle mainBundle] URLForResource:name withExtension:@"aif"];
	if (url != nil) {
		OSStatus err = AudioServicesCreateSystemSoundID ((__bridge CFURLRef) url, &soundID);
		if (err) NSLog (@"AudioServicesCreateSystemSoundID error %ld", (long)err);
	}
	return soundID;
}

#pragma mark - Playback

- (void)playSound:(SystemSoundID)soundID {
	if ([SoundEffects soundEffectsEnabled])
		AudioServicesPlaySystemSound(soundID);
}

- (void)playSoundWithNumber:(NSNumber *)soundNumber {
	[self playSound:[soundNumber intValue]];
}

#pragma mark - Individual Sounds

- (void)playSilence {
	[self playSound:silenceSound];
}

- (void)playAppIntroSound {
	[self playSound:appIntroSound];
}

- (void)playUnlockSound {
	[self playSound:unlockSound];
}

- (void)playLockSound {
	[self playSound:lockSound];
}

- (void)playOpenTileEditorSound {
	[self performSelector:@selector(playSoundWithNumber:) withObject:@(zoomInDoubleSound) afterDelay:0.25];
}

- (void)playCloseTileEditorSound {
	[self performSelector:@selector(playSoundWithNumber:) withObject:@(zoomOutSound) afterDelay:0.495];
}

- (void)playColorPaletteClickSound {
	[self playSound:colorPaletteSwipeSound];
}

- (void)playTilePaletteClickSound {
	[self playSound:tilePaletteClickSound];
}

- (void)playDuplicateArtboardSound {
	[self performSelector:@selector(playSoundWithNumber:) withObject:@(zoomInDoubleSound) afterDelay:1.75];
}

- (void)playDeleteArtboardSound {
	[self performSelector:@selector(playSoundWithNumber:) withObject:@(artboardDeleteSound) afterDelay:0.4];
}

- (void)playOpenViewerSound {
	[self performSelector:@selector(playSoundWithNumber:) withObject:@(zoomInSound) afterDelay:0.45];
}

- (void)playCloseViewerSound {
	[self performSelector:@selector(playSoundWithNumber:) withObject:@(zoomOutSound) afterDelay:0.495];
}

- (void)playOpenSheetSound {
	[self performSelector:@selector(playSoundWithNumber:) withObject:@(slideDialogSound) afterDelay:0.125];
}

- (void)playCloseSheetSound {
	[self performSelector:@selector(playSoundWithNumber:) withObject:@(zoomOutSound) afterDelay:0.495];
}

- (void)playDrawerOpenCloseSound {
	[self playSound:drawerOpenSound];
}

- (void)playTilePlaceSoundAtX:(int)x y:(int)y {
	int index = (x + y + 1) % 2;
	[self performSelector:@selector(playSoundWithNumber:) withObject:@(tilePlaceSound[index]) afterDelay:0.020];
}

- (void)playTileRotationSound {
	[self playSound:tileRotateSound];
}

- (void)playTileRotationStartedSoundWithTapCount:(int)tapCount {
    // negative values are passed in during undo
    tapCount = abs(tapCount);
    
	// Orientation and is currently not used, but might be in the future for playing different sounds or modulation.
	// Schedule the tap sounds so the end when the animation ends.
	const NSTimeInterval kTileRotationDuration = 0.2;
	const NSTimeInterval kTileRotationSoundSpacing = 0.0625;
	NSTimeInterval delay = kTileRotationDuration;
	
	for (int i = 0; i < tapCount; i++) {
		[self performSelector:@selector(playSoundWithNumber:) withObject:@(tileRotateSound) afterDelay:delay];
		delay -= kTileRotationSoundSpacing;
	}
}

- (void)playTileDroppedSound {
	[self playSound:tileDropSound];
}

- (void)playSelectColorSound {
	[self playSound:selectColorSound];
}

- (void)playChangeColorSound {
	[self playSound:changeColorSound];
}

- (void)playPaintSoundAtX:(int)x y:(int)y {
	int index = (3 + x + y) % 4;
	[self playSound:paintSound[index]];
}

@end
