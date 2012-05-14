//
//  MLGViewController.m
//  MGTileMenu
//
//  Created by Matt Gemmell on 27/01/2012.
//  Copyright (c) 2012 Instinctive Code.
//

#import "MLGViewController.h"

@implementation MLGViewController


@synthesize tileController;


#pragma mark - TileMenu delegate


- (NSInteger)numberOfTilesInMenu:(MGTileMenuController *)tileMenu
{
	return 9;
}


- (UIImage *)imageForTile:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu
{
	NSArray *images = [NSArray arrayWithObjects:
					   @"twitter", 
					   @"key", 
					   @"speech", 
					   @"magnifier", 
					   @"scissors", 
					   @"actions", 
					   @"Text", 
					   @"heart", 
					   @"gear", 
					   nil];
	if (tileNumber >= 0 && tileNumber < images.count) {
		return [UIImage imageNamed:[images objectAtIndex:tileNumber]];
	}
	
	return [UIImage imageNamed:@"Text"];
}


- (NSString *)labelForTile:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu
{
	NSArray *labels = [NSArray arrayWithObjects:
					   @"Twitter", 
					   @"Key", 
					   @"Speech balloon", 
					   @"Magnifying glass", 
					   @"Scissors", 
					   @"Actions", 
					   @"Text", 
					   @"Heart", 
					   @"Settings", 
					   nil];
	if (tileNumber >= 0 && tileNumber < labels.count) {
		return [labels objectAtIndex:tileNumber];
	}
	
	return @"Tile";
}


- (NSString *)descriptionForTile:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu
{
	NSArray *hints = [NSArray arrayWithObjects:
					   @"Sends a tweet", 
					   @"Unlock something", 
					   @"Sends a message", 
					   @"Zooms in", 
					   @"Cuts something", 
					   @"Shows export options", 
					   @"Adds some text", 
					   @"Marks something as a favourite", 
					   @"Shows some settings", 
					   nil];
	if (tileNumber >= 0 && tileNumber < hints.count) {
		return [hints objectAtIndex:tileNumber];
	}
	
	return @"It's a tile button!";
}


- (UIImage *)backgroundImageForTile:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu
{
	if (tileNumber == 1) {
		return [UIImage imageNamed:@"purple_gradient"];
	} else if (tileNumber == 4) {
		return [UIImage imageNamed:@"orange_gradient"];
	} else if (tileNumber == 7) {
		return [UIImage imageNamed:@"red_gradient"];
	} else if (tileNumber == 5) {
		return [UIImage imageNamed:@"yellow_gradient"];
	} else if (tileNumber == 8) {
		return [UIImage imageNamed:@"green_gradient"];
	} else if (tileNumber == -1) {
		return [UIImage imageNamed:@"grey_gradient"];
	}
	
	return [UIImage imageNamed:@"blue_gradient"];
}


- (BOOL)isTileEnabled:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu
{
	if (tileNumber == 2 || tileNumber == 6) {
		return NO;
	}
	
	return YES;
}


- (void)tileMenu:(MGTileMenuController *)tileMenu didActivateTile:(NSInteger)tileNumber
{
	NSLog(@"Tile %d activated (%@)", tileNumber, [self labelForTile:tileNumber inMenu:tileController]);
}


- (void)tileMenuDidDismiss:(MGTileMenuController *)tileMenu
{
	tileController = nil;
}


#pragma mark - Gesture handling


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	// Ensure that only touches on our own view are sent to the gesture recognisers.
	if (touch.view == self.view) {
		return YES;
	}
	
	return NO;
}


- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
	// Find out where the gesture took place.
	CGPoint loc = [gestureRecognizer locationInView:self.view];
	if ([gestureRecognizer isMemberOfClass:[UITapGestureRecognizer class]] && ((UITapGestureRecognizer *)gestureRecognizer).numberOfTapsRequired == 2) {
		// This was a double-tap.
		// If there isn't already a visible TileMenu, we should create one if necessary, and show it.
		if (!tileController || tileController.isVisible == NO) {
			if (!tileController) {
				// Create a tileController.
				tileController = [[MGTileMenuController alloc] initWithDelegate:self];
				tileController.dismissAfterTileActivated = NO; // to make it easier to play with in the demo app.
			}
			// Display the TileMenu.
			[tileController displayMenuCenteredOnPoint:loc inView:self.view];
		}
		
	} else {
		// This wasn't a double-tap, so we should hide the TileMenu if it exists and is visible.
		if (tileController && tileController.isVisible == YES) {
			// Only dismiss if the tap wasn't inside the tile menu itself.
			if (!CGRectContainsPoint(tileController.view.frame, loc)) {
				[tileController dismissMenu];
			}
		}
	}
}


#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Set up recognizers.
	UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
	doubleTapRecognizer.numberOfTapsRequired = 2;
	doubleTapRecognizer.delegate = self;
	[self.view addGestureRecognizer:doubleTapRecognizer];
	
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
	tapRecognizer.delegate = self;
	[self.view addGestureRecognizer:tapRecognizer];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}


@end
