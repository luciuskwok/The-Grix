//
//  InfoViewController.m
//  eboy
//
//  Created by Brian Papa on 12/4/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "InfoViewController.h"
#import "eboyAppDelegate.h"
#import "IntroViewController.h"
#import "UIView+Setup.h"


@implementation InfoViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.view setupSubviewsToBePixelatedAndExclusiveTouch];
}

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)replayIntro:(id)sender {
	IntroViewController *intro = [[IntroViewController alloc] init];
	[self presentViewController:intro animated:NO completion:nil];
}

- (IBAction)openGrixURL:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://thegrix.com"]];
}

- (IBAction)openFeltTipURL:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://felttip.com"]];
}

- (IBAction)openEboyURL:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://hello.eboy.com"]];
}

@end
