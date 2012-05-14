//
//  MGTileMenuController.m
//  MGTileMenu
//
//  Created by Matt Gemmell on 27/01/2012.
//  Copyright (c) 2012 Instinctive Code.
//

#import "MGTileMenuController.h"
#import "MGTileMenuView.h"
#import <QuartzCore/QuartzCore.h>


// Various keys for internal use.
#define MG_ANIMATION_APPEAR		@"Appear"
#define MG_ANIMATION_DISAPPEAR	@"Disappear"
#define MG_ANIMATION_TILES		@"Tiles"
#define MG_ANIMATION_TILE_LAYER	@"TileLayer"
#define MG_ANIMATION_TILE_INDEX	@"TileIndex"
// Geometry and appearance.
#define MG_PARENTVIEW_EDGE_INSET	3.0 // minimum inset in pixels from edges of parent view
#define MG_TILES_PER_PAGE	5 // not including paging tile (or Close button)
#define MG_DISABLED_TILE_OPACITY	0.65 // from 0.0 (fully transparent/hidden) to 1.0 (fully opaque/visible)
// Timing.
#define MG_ANIMATION_DURATION	0.15 // seconds
#define MG_ACTIVATION_DISMISS_DELAY	0.25 // seconds; delay between activating a tile and auto-dismissing the menu (if appropriate)


// Notifications.
NSString *MGTileMenuWillDisplayNotification;
NSString *MGTileMenuDidDisplayNotification;
NSString *MGTileMenuWillDismissNotification;
NSString *MGTileMenuDidDismissNotification;
NSString *MGTileMenuDidActivateTileNotification;
NSString *MGTileMenuDidSelectTileNotification;
NSString *MGTileMenuDidDeselectTileNotification;
NSString *MGTileMenuWillSwitchToPageNotification;
NSString *MGTileMenuDidSwitchToPageNotification;


@implementation MGTileMenuController

@synthesize delegate = _delegate;
@synthesize centerPoint = _centerPoint;
@synthesize parentView = _parentView;
@synthesize isVisible = _isVisible;
@synthesize currentPage = _currentPage;

@synthesize dismissAfterTileActivated = _dismissAfterTileActivated;
@synthesize rightHanded = _rightHanded;
@synthesize shadowsEnabled = _shadowsEnabled;
@synthesize tileSide = _tileSide;
@synthesize tileGap = _tileGap;
@synthesize cornerRadius = _cornerRadius;
@synthesize tileGradient = _tileGradient;
@synthesize selectionBorderWidth = _selectionBorderWidth;
@synthesize selectionGradient = _selectionGradient;
@synthesize bezelColor = _bezelColor;
@synthesize closeButtonImage = _closeButtonImage;
@synthesize selectedCloseButtonImage = _selectedCloseButtonImage;
@synthesize pageButtonImage = _pageButtonImage;
@synthesize shouldMoveToStayVisibleAfterRotation = _shouldMoveToStayVisibleAfterRotation;
@synthesize closeButtonVisible = _closeButtonVisible;


#pragma mark - Creation and destruction


- (id)initWithDelegate:(id<MGTileMenuDelegate>)theDelegate
{
    if (theDelegate && [theDelegate conformsToProtocol:@protocol(MGTileMenuDelegate)]) {
        _delegate = theDelegate;
        return (self = [self initWithNibName:nil bundle:nil]);
    }
    
    return nil;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _centerPoint = CGPointZero;
        _isVisible = NO;
		_currentPage = 0;
        _dismissAfterTileActivated = YES;
        _rightHanded = YES;
        _shadowsEnabled = YES;
        _tileSide = 72;
        _tileGap = 20;
		_cornerRadius = 12.0;
		_tileGradient = MGCreateGradientWithColors([UIColor colorWithRed:0.28 green:0.67 blue:0.90 alpha:1.0], 
												   [UIColor colorWithRed:0.19 green:0.46 blue:0.76 alpha:1.0]);		
		_selectionBorderWidth = 5;
		_selectionGradient = MGCreateGradientWithColors([UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], 
														[UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0]);
		_bezelColor = [UIColor colorWithWhite:0 alpha:0.50];
        _closeButtonImage = nil;
        _selectedCloseButtonImage = nil;
        _pageButtonImage = nil;
		_shouldMoveToStayVisibleAfterRotation = YES;
		_closeButtonVisible = YES;
		
		// Clockwise from left.
		_animationOrder = [NSMutableArray arrayWithObjects:
						   [NSNumber numberWithInteger:3], 
						   [NSNumber numberWithInteger:0], 
						   [NSNumber numberWithInteger:1], 
						   [NSNumber numberWithInteger:2], 
						   [NSNumber numberWithInteger:4], 
						  nil];
		
		_singlePageMaxTiles = NO;
    }
    return self;
}


- (void)dealloc
{
	CGGradientRelease(_tileGradient);
	CGGradientRelease(_selectionGradient);
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
	// Bezel
	NSInteger bezelSize = (self.tileSide * 3) + (self.tileGap * 2);
    self.view = [[MGTileMenuView alloc] initWithFrame:CGRectMake(0, 0, bezelSize, bezelSize)];
	((MGTileMenuView *)(self.view)).controller = self;
	
	self.view.opaque = NO;
	self.view.backgroundColor = [UIColor clearColor];
	self.view.layer.opaque = NO;
	
	self.view.layer.shadowRadius = 5.0;
	self.view.layer.shadowOpacity = 0.75;
	self.view.layer.shadowOffset = CGSizeMake(0, 5);
	if (!_shadowsEnabled) {
		self.view.layer.shadowRadius = 0.0;
		self.view.layer.shadowOffset = CGSizeZero;
	}
	
	// Close button
	_closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	UIImage *closeImage;
	if (_closeButtonImage != nil) {
		closeImage = _closeButtonImage;
	} else {
		closeImage = [UIImage imageNamed:@"CloseButton"];
	}
	_closeButton.accessibilityLabel = NSLocalizedString(@"Close", @"Accessibility label for Close button");
	_closeButton.accessibilityHint = NSLocalizedString(@"Closes the menu", @"Accessibility hint for Close button");
	CGRect closeFrame = CGRectZero;
	closeFrame.size = closeImage.size;
	_closeButton.frame = closeFrame;
	[_closeButton setBackgroundImage:closeImage forState:UIControlStateNormal];
	if (_selectedCloseButtonImage != nil) {
		[_closeButton setBackgroundImage:_selectedCloseButtonImage forState:UIControlStateHighlighted];
	} else {
		[_closeButton setBackgroundImage:nil forState:UIControlStateHighlighted];
	}
	[_closeButton addTarget:self action:@selector(dismissMenu) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_closeButton];
	
	// Tiles
	_tileButtons = [NSMutableArray arrayWithCapacity:6];
	UIImage *tileImage = [self tileBackgroundImageHighlighted:NO];
	UIButton *tileButton;
	CGRect tileFrame = CGRectZero;
	tileFrame.size = tileImage.size;
	
	NSInteger j;
	NSInteger numTiles = MG_TILES_PER_PAGE;
	if (_singlePageMaxTiles) {
		numTiles++;
		[_animationOrder insertObject:[NSNumber numberWithInteger:5] atIndex:0];
	}
	for (int i = 0; i < (numTiles + 1); i++) {
		tileButton = [UIButton buttonWithType:UIButtonTypeCustom];
		tileButton.userInteractionEnabled = NO;
		tileButton.tag = i;
		tileButton.frame = [self frameForCenteredTile];
		if (i == numTiles) {
			// Page-switching button.
			tileButton.layer.zPosition = 0;
			tileButton.frame = [self frameForTileAtIndex:i];
			[tileButton addTarget:self action:@selector(goToNextPage) forControlEvents:UIControlEventTouchUpInside];
			_pageButton = tileButton;
			UIImage *ellipsisImage;
			if (_pageButtonImage != nil) {
				ellipsisImage = _pageButtonImage;
			} else {
				ellipsisImage = [UIImage imageNamed:@"ellipsis"];
			}
			[_pageButton setImage:ellipsisImage forState:UIControlStateNormal];
			[_pageButton setImage:ellipsisImage forState:UIControlStateHighlighted];
			UIImage *tileHighlightedImage = [self tileBackgroundImageHighlighted:YES];
			[tileButton setBackgroundImage:tileImage forState:UIControlStateNormal];
			[tileButton setBackgroundImage:tileHighlightedImage forState:UIControlStateHighlighted];
		} else {
			j = [[_animationOrder objectAtIndex:i] integerValue];
			if (_rightHanded) {
				tileButton.layer.zPosition = (numTiles - [_animationOrder indexOfObject:[NSNumber numberWithInt:i]]);
			} else {
				tileButton.layer.zPosition = [_animationOrder indexOfObject:[NSNumber numberWithInt:i]];
			}
			[tileButton addTarget:self action:@selector(tileActivated:) forControlEvents:UIControlEventTouchUpInside];
			[tileButton addTarget:self action:@selector(tileSelected:) 
				 forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
			[tileButton addTarget:self action:@selector(tileDeselected:) 
				 forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchDragExit];
			[_tileButtons addObject:tileButton];
		}
		[self.view addSubview:tileButton];
	}
	
	_appeared = NO;
}


- (void)viewDidUnload
{
	[super viewDidUnload];
    
	self.bezelColor = nil;
	self.closeButtonImage = nil;
	self.pageButtonImage = nil;
	self.selectedCloseButtonImage = nil;
	_animationOrder = nil;
	_closeButton = nil;
	_pageButton = nil;
	_tileButtons = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceDidRotate:)
												 name:@"UIDeviceOrientationDidChangeNotification"
											   object:nil];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:@"UIDeviceOrientationDidChangeNotification" 
												  object:nil];
}


#pragma mark - Rotation


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}


- (void)deviceDidRotate:(NSNotification *)notification
{
	if (_shouldMoveToStayVisibleAfterRotation && self.view.superview != nil) {
		// Adjust centerPt if necessary to fit on-screen.
		CGRect newFrame = MGMinimallyOverlapRects(self.view.frame, _parentView.bounds, MG_PARENTVIEW_EDGE_INSET);
		
		// Move bezel view to actual center point.
		_centerPoint = CGPointMake(CGRectGetMidX(newFrame), CGRectGetMidY(newFrame));
		self.view.frame = newFrame;
	}
}


#pragma mark - Utilities


// Moves 'inner' rect the minimum distance to ensure it fully overlaps (is contained within) 'outer'.
// Does not attempt to do the reverse (i.e. to overlap 'outer' upon 'inner').
// The 'padding' parameter insets 'inner' by 'padding' pixels within 'outer', i.e. adds a clear margin.
// Will obviously not be possible if inner is larger than outer in either dimension;
//      in this situation, the inner rect will be returned unchanged.
// This function is useful for ensuring that a given rect is fully visible within another (e.g. is fully on-screen).
CGRect MGMinimallyOverlapRects(CGRect inner, CGRect outer, CGFloat padding)
{
    CGRect newInner = inner;
    CGFloat doublePadding = padding * 2.0;
    
    if ((inner.size.width + doublePadding) <= outer.size.width && (inner.size.height + doublePadding) <= outer.size.height) {
        
        // Left edge
        if (newInner.origin.x < (outer.origin.x + padding)) {
            newInner.origin.x = (outer.origin.x + padding);
        }
        
        // Top edge
        if (newInner.origin.y < (outer.origin.y + padding)) {
            newInner.origin.y = (outer.origin.y + padding);
        }
        
        // Right edge
        if (CGRectGetMaxX(newInner) > (CGRectGetMaxX(outer) - padding)) {
            newInner.origin.x = CGRectGetMaxX(outer) - (padding + newInner.size.width);
        }
        
        // Bottom edge
        if (CGRectGetMaxY(newInner) > (CGRectGetMaxY(outer) - padding)) {
            newInner.origin.y = CGRectGetMaxY(outer) - (padding + newInner.size.height);
        }
    }
    
    return newInner;
}


CGPoint MGCenterPoint(CGRect rect)
{
	return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}


CGGradientRef MGCreateGradientWithColors(UIColor *topColorRGB, UIColor *bottomColorRGB)
{
	CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
	CGFloat locations[2] = {0, 1};
	CGFloat topRed, topGreen, topBlue, topAlpha, bottomRed, bottomGreen, bottomBlue, bottomAlpha;
	[topColorRGB getRed:&topRed green:&topGreen blue:&topBlue alpha:&topAlpha];
	[bottomColorRGB getRed:&bottomRed green:&bottomGreen blue:&bottomBlue alpha:&bottomAlpha];
	CGFloat gradientColors[] =
	{
		topRed, topGreen, topBlue, topAlpha, 
		bottomRed, bottomGreen, bottomBlue, bottomAlpha,
	};
	CGGradientRef gradient = CGGradientCreateWithColorComponents(rgb, gradientColors, locations, 2);
	CGColorSpaceRelease(rgb);
	
	return gradient; // follows the "Create rule"; i.e. must be released by caller (even with ARC)
}


- (NSInteger)nextPageNumber:(NSInteger)currentPageNumber
{
	NSInteger nextPageNumber = currentPageNumber + 1;
	
	// Constrain nextPageNumber to feasible values.
	NSInteger totalTiles = [_delegate numberOfTilesInMenu:self];
	NSInteger lastPage = ceil((CGFloat)totalTiles / (CGFloat)MG_TILES_PER_PAGE) - 1; // zero-based
	if (nextPageNumber < 0) {
		nextPageNumber = 0;
	} else if (nextPageNumber > lastPage) {
		nextPageNumber = 0;
	}
	
	return nextPageNumber;
}


- (UIBezierPath *)_bezelPath
{
	CGRect bezelRect = self.view.bounds;
	CGFloat halfTile = (CGFloat)(self.tileSide) / 2.0;
	bezelRect.origin.x += halfTile;
	bezelRect.origin.y += halfTile;
	bezelRect.size.width -= self.tileSide;
	bezelRect.size.height -= self.tileSide;
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bezelRect 
													cornerRadius:_cornerRadius];
	return path;
}


// Returns the appropriate frame (within bezel view) for a tile at the given zero-based index.
// There are:
//		three tiles (0-2) on the top row
//		two tiles (3-4) on the middle row, on the left and right
//		one tile (5) on the bottom row, either on the left (if right-handed) or right (if left-handed)
// The central position is excluded, since it is reserved for the Close button.
// Specifying an out-of-bounds tileNumber (<0 or >5) returns the frame for tile 0.
- (CGRect)frameForTileAtIndex:(NSInteger)tileNumber
{
	// We start with the correct frame for tile 0.
	CGRect frame = CGRectMake(0, 0, _tileSide, _tileSide);
	
	// Modify frame for other tiles.
	if (tileNumber >= 1 && tileNumber <= 5) {
		// x-coordinate
		if (tileNumber == 1) {
			// Top middle.
			frame.origin.x = (_tileSide + _tileGap);
		} else if (tileNumber == 2 || tileNumber == 4 || (tileNumber == 5 && !_rightHanded)) {
			// Top right, middle right, or bottom right.
			frame.origin.x = (_tileSide + _tileGap) * 2;
		}
		
		// y-coordindate
		if (tileNumber == 3 || tileNumber == 4) {
			frame.origin.y = (_tileSide + _tileGap);
		} else if (tileNumber == 5) {
			frame.origin.y = (_tileSide + _tileGap) * 2;
		}
	}
	
	return frame;
}


- (CGRect)frameForCenteredTile
{
	CGRect frame = CGRectMake(0, 0, _tileSide, _tileSide);
	CGRect bezelBounds = self.view.bounds;
	frame.origin.x = (bezelBounds.size.width - _tileSide) / 2.0;
	frame.origin.y = (bezelBounds.size.height - _tileSide) / 2.0;
	return frame;
}


- (UIImage *)tileBackgroundImageHighlighted:(BOOL)highlighted
{
	// Used for the page-switching tile.
	return [self tileBackgroundImageForTile:MG_PAGE_SWITCHING_TILE_INDEX highlighted:highlighted];
}


- (UIImage *)tileBackgroundImageForTile:(NSInteger)tileNumber highlighted:(BOOL)highlighted
{
	// Ask delegate for a suitable background image, gradient or colour for the tile, and render appropriately.
	// We'll fall back on the default _tileGradient if required.
	
	CGRect tileRect = CGRectMake(0, 0, _tileSide, _tileSide);
	if (UIGraphicsBeginImageContextWithOptions != NULL) {
		UIGraphicsBeginImageContextWithOptions(tileRect.size, NO, 0.0);
	} else {
		UIGraphicsBeginImageContext(tileRect.size);
	}
	CGContextRef context = UIGraphicsGetCurrentContext();
	UIGraphicsPushContext(context);
	
	// Clip drawing to within tile's rounded path.
	CGContextSaveGState(context);
	UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:tileRect cornerRadius:_cornerRadius];
	[roundedPath addClip];
	
	// Fill rounded path with relevant background.
	CGRect pathBoundsRect = [roundedPath bounds];
	CGPoint start = CGPointMake(CGRectGetMidX(pathBoundsRect), CGRectGetMinY(pathBoundsRect));
	CGPoint end = CGPointMake(CGRectGetMidX(pathBoundsRect), CGRectGetMaxY(pathBoundsRect));
	
	BOOL drawnBackground = NO;
	if (_delegate) {
		if ([_delegate respondsToSelector:@selector(backgroundImageForTile:inMenu:)]) {
			UIImage *bg = [_delegate backgroundImageForTile:tileNumber inMenu:self];
			if (bg != nil) {
				[bg drawInRect:pathBoundsRect];
				drawnBackground = YES;
			}
		}
		
		if (!drawnBackground && [_delegate respondsToSelector:@selector(gradientForTile:inMenu:)]) {
			CGGradientRef gradient = [_delegate gradientForTile:tileNumber inMenu:self];
			if (gradient != NULL) {
				CGContextDrawLinearGradient(context, gradient, start, end, 0);
				drawnBackground = YES;
			}
		}
		
		if (!drawnBackground && [_delegate respondsToSelector:@selector(colorForTile:inMenu:)]) {
			UIColor *color = [_delegate colorForTile:tileNumber inMenu:self];
			if (color != nil) {
				[color set];
				UIRectFill(pathBoundsRect);
				drawnBackground = YES;
			}
		}
	}
	
	if (!drawnBackground) {
		CGContextDrawLinearGradient(context, _tileGradient, start, end, 0);
	}
	
	CGContextRestoreGState(context);
	
	// Expand the clipping area slightly so tile background doesn't show as a fringe around the corners.
	CGFloat factor = -0.4;
	CGRect expandedRect = CGRectInset(tileRect, factor, factor);
	UIBezierPath *expandedPath = [UIBezierPath bezierPathWithRoundedRect:expandedRect 
															cornerRadius:_cornerRadius + 1.0];
	[expandedPath addClip];
	
	// 'Stroke' path with gradient if highlighted.
	if (highlighted) {
		// Obtain path for a border around roundedPath, of twice the selectionBorderWidth.
		CGPathRef borderPath = CGPathCreateCopyByStrokingPath(roundedPath.CGPath, NULL, 
															  (_selectionBorderWidth * 2.0), 
															  roundedPath.lineCapStyle, 
															  roundedPath.lineJoinStyle, 
															  roundedPath.miterLimit);
		
		// Clip to path.
		CGContextAddPath(context, borderPath);
		CGContextClip(context);
		
		// Draw selection gradient.
		CGContextDrawLinearGradient(context, _selectionGradient, start, end, 0);
		
		// Dispose of temporary border path.
		CGPathRelease(borderPath);
	}
	
	UIGraphicsPopContext();								
	UIImage *tileImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return tileImage;
}


- (void)tileActivated:(id)sender
{
	// Inform delegate.
	NSInteger tileNumber = ((UIButton *)sender).tag + (_currentPage * MG_TILES_PER_PAGE);
	if (self.delegate && [self.delegate respondsToSelector:@selector(tileMenu:didActivateTile:)]) {
		[self.delegate tileMenu:self didActivateTile:tileNumber];
	}
	
	// Send notification.
	NSDictionary *info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:tileNumber] 
													 forKey:MGTileNumberKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGTileMenuDidActivateTileNotification 
														object:self 
													  userInfo:info];
	
	// Dismiss if appropriate.
	if (self.dismissAfterTileActivated) {
		[self performSelector:@selector(dismissMenu) withObject:nil afterDelay:MG_ACTIVATION_DISMISS_DELAY];
	}
}


- (void)tileSelected:(id)sender
{
	// Inform delegate.
	NSInteger tileNumber = ((UIButton *)sender).tag + (_currentPage * MG_TILES_PER_PAGE);
	if (self.delegate && [self.delegate respondsToSelector:@selector(tileMenu:didSelectTile:)]) {
		[self.delegate tileMenu:self didSelectTile:tileNumber];
	}
	
	// Send notification.
	NSDictionary *info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:tileNumber] 
													 forKey:MGTileNumberKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGTileMenuDidSelectTileNotification 
														object:self 
													  userInfo:info];
}


- (void)tileDeselected:(id)sender
{
	// Inform delegate.
	NSInteger tileNumber = ((UIButton *)sender).tag + (_currentPage * MG_TILES_PER_PAGE);
	if (self.delegate && [self.delegate respondsToSelector:@selector(tileMenu:didDeselectTile:)]) {
		[self.delegate tileMenu:self didDeselectTile:tileNumber];
	}
	
	// Send notification.
	NSDictionary *info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:tileNumber] 
													 forKey:MGTileNumberKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGTileMenuDidDeselectTileNotification 
														object:self 
													  userInfo:info];
}


#pragma mark - Displaying and dismissing the menu


// Display the menu. Returns the actual center-point used (may be shifted from centerPt to fit fully on-screen, if possible).
- (CGPoint)displayMenuCenteredOnPoint:(CGPoint)centerPt inView:(UIView *)parentView
{
	return [self displayMenuPage:0 centeredOnPoint:centerPt inView:parentView];
}


// As above, with the menu already displaying the specified 'page' of tiles.
- (CGPoint)displayMenuPage:(NSInteger)pageNum centeredOnPoint:(CGPoint)centerPt inView:(UIView *)parentView
{
	if (!parentView) {
		return CGPointZero;
	}
	_parentView = parentView;
	_currentPage = pageNum;
	_tilesArranged = NO;
	_animatingTiles = NO;
	_tileAnimationInterrupted = NO;
	
	// Inform delegate.
	if (_delegate && [_delegate respondsToSelector:@selector(tileMenuWillDisplay:)]) {
		[_delegate tileMenuWillDisplay:self];
	}
	
	// Send notification.
	[[NSNotificationCenter defaultCenter] postNotificationName:MGTileMenuWillDisplayNotification 
														object:self 
													  userInfo:nil];
	
	// Determine if this is the exceptional case of having exactly 6 tiles.
	// This is exceptional because we will show 6 normal tiles instead of 5,
	// and will not show the page-switching tile.
	_singlePageMaxTiles = ([_delegate numberOfTilesInMenu:self] == MG_TILES_PER_PAGE + 1);
	
    // Adjust size of view, in case our settings have changed.
	NSInteger bezelSize = (self.tileSide * 3) + (self.tileGap * 2);
    
	// Adjust centerPt if necessary to fit on-screen.
	NSInteger halfBezel = bezelSize / 2;
	CGRect newFrame = CGRectMake(centerPt.x - halfBezel, centerPt.y - halfBezel, bezelSize, bezelSize);
	newFrame = MGMinimallyOverlapRects(newFrame, parentView.bounds, MG_PARENTVIEW_EDGE_INSET);
	
	// Move bezel view to actual center point.
	_centerPoint = CGPointMake(CGRectGetMidX(newFrame), CGRectGetMidY(newFrame));
	self.view.frame = newFrame;
	
	// Position close button.
	CGPoint closeCenter = _centerPoint;
	closeCenter.x -= newFrame.origin.x;
	closeCenter.y -= newFrame.origin.y;
	_closeButton.center = closeCenter;
	_closeButton.hidden = !_closeButtonVisible;
	_closeButton.userInteractionEnabled = NO;
	
	// Position tiles.
	for (UIButton *tileButton in _tileButtons) {
		tileButton.frame = [self frameForCenteredTile];
		tileButton.layer.position = closeCenter;
		[tileButton.layer removeAllAnimations];
	}
	
	// Display menu.
	[_parentView addSubview:self.view];
	
	// Add appearance animations.
	NSArray *animations = [self _animationsForAppearing:YES];
	int i = 0;
	for (CAAnimation *animation in animations) {
		[self.view.layer addAnimation:animation forKey:[NSString stringWithFormat:@"%d", i]];
		i++;
	}
	
	if (!_rightHanded) {
		// Switch to counterclockwise-from-right animation order.
		_animationOrder = [NSMutableArray arrayWithObjects:
						   [NSNumber numberWithInteger:4], 
						   [NSNumber numberWithInteger:2], 
						   [NSNumber numberWithInteger:1], 
						   [NSNumber numberWithInteger:0], 
						   [NSNumber numberWithInteger:3], 
						   nil];
	}
	
	// Alter animation order for the extra tile.
	if (_singlePageMaxTiles && _animationOrder.count == MG_TILES_PER_PAGE) {
		[_animationOrder insertObject:[NSNumber numberWithInteger:5] atIndex:0];
	}
	
	// Configure and display appropriate page of menu.
	[self switchToPage:pageNum];
	
	return _centerPoint;
}


// Immediately dismiss/hide the menu, cancelling further interaction.
- (void)dismissMenu
{
	if ([self isVisible]) {
		
		// Check with delegate.
		BOOL shouldDismiss = YES;
		if (_delegate && [_delegate respondsToSelector:@selector(tileMenuShouldDismiss:)]) {
			shouldDismiss = [_delegate tileMenuShouldDismiss:self];
		}
		
		if (shouldDismiss) {
			// Add disappearance animations.
			NSArray *animations = [self _animationsForAppearing:NO];
			int i = 0;
			for (CAAnimation *animation in animations) {
				[self.view.layer addAnimation:animation forKey:[NSString stringWithFormat:@"%d", i]];
				i++;
			}
			
			// Inform delegate.
			if (_delegate && [_delegate respondsToSelector:@selector(tileMenuWillDismiss:)]) {
				[_delegate tileMenuWillDismiss:self];
			}
			
			// Send notification.
			[[NSNotificationCenter defaultCenter] postNotificationName:MGTileMenuWillDismissNotification
																object:self 
															  userInfo:nil];
		}
	}
}


- (BOOL)isVisible
{
	return (self.view && self.parentView && self.view.superview && ![self.view isHidden] && _appeared);
}


#pragma mark - Animations


- (NSArray *)_animationsForAppearing:(BOOL)appearing
{
	NSMutableArray *animations = [NSMutableArray arrayWithCapacity:0];
	
	if (appearing) {
		CABasicAnimation *expandAnimation;
		expandAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
		[expandAnimation setValue:MG_ANIMATION_APPEAR forKey:@"name"];
		[expandAnimation setRemovedOnCompletion:NO];
		[expandAnimation setDuration:MG_ANIMATION_DURATION];
		[expandAnimation setFillMode:kCAFillModeForwards];
		[expandAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
		[expandAnimation setDelegate:self];
		CGFloat factor = 0.6;
		CATransform3D transform = CATransform3DMakeScale(factor, factor, factor);
		expandAnimation.fromValue = [NSValue valueWithCATransform3D:transform];
		expandAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
		
		[animations addObject:expandAnimation];
		
		CABasicAnimation *fadeAnimation;
		fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		[fadeAnimation setValue:MG_ANIMATION_APPEAR forKey:@"name"];
		[fadeAnimation setRemovedOnCompletion:NO];
		[fadeAnimation setDuration:MG_ANIMATION_DURATION];
		[fadeAnimation setFillMode:kCAFillModeForwards];
		[fadeAnimation setDelegate:self];
		fadeAnimation.fromValue = [NSNumber numberWithFloat:0.0];
		fadeAnimation.toValue = [NSNumber numberWithFloat:1.0];
		
		[animations addObject:fadeAnimation];
		
	} else {
		CABasicAnimation *shrinkAnimation;
		shrinkAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
		[shrinkAnimation setValue:MG_ANIMATION_DISAPPEAR forKey:@"name"];
		[shrinkAnimation setRemovedOnCompletion:NO];
		[shrinkAnimation setDuration:MG_ANIMATION_DURATION];
		[shrinkAnimation setFillMode:kCAFillModeForwards];
		[shrinkAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
		[shrinkAnimation setDelegate:self];
		shrinkAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
		CGFloat factor = 0.6;
		CATransform3D transform = CATransform3DMakeScale(factor, factor, factor);
		shrinkAnimation.toValue = [NSValue valueWithCATransform3D:transform];
		
		[animations addObject:shrinkAnimation];
		
		CABasicAnimation *fadeAnimation;
		fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		[fadeAnimation setValue:MG_ANIMATION_DISAPPEAR forKey:@"name"];
		[fadeAnimation setRemovedOnCompletion:NO];
		[fadeAnimation setDuration:MG_ANIMATION_DURATION];
		[fadeAnimation setFillMode:kCAFillModeForwards];
		[fadeAnimation setDelegate:self];
		fadeAnimation.fromValue = [NSNumber numberWithFloat:1.0];
		fadeAnimation.toValue = [NSNumber numberWithFloat:0.0];
		
		[animations addObject:fadeAnimation];
	}
	
	return animations;
}


- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished
{
	BOOL continueAnimation = NO;
	BOOL cleanUp = NO;
	CALayer *layer = [animation valueForKey:MG_ANIMATION_TILE_LAYER];
	NSString *path = nil;
	NSValue *fromValue = nil;
	
	if (!layer) {
		layer = self.view.layer;
	}
	
	if (animation) {
		NSString *name = [animation valueForKey:@"name"];
		if ([name isEqualToString:MG_ANIMATION_DISAPPEAR]) {
			cleanUp = YES;
		} else if ([name isEqualToString:MG_ANIMATION_APPEAR]) {
			
			// Inform delegate.
			if (!_appeared && _delegate && [_delegate respondsToSelector:@selector(tileMenuDidDisplay:)]) {
				[_delegate tileMenuDidDisplay:self];
			}
			
			// Send notification.
			[[NSNotificationCenter defaultCenter] postNotificationName:MGTileMenuDidDisplayNotification 
																object:self 
															  userInfo:nil];
			
			_appeared = YES;
			
			NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[_closeButton methodSignatureForSelector:@selector(setUserInteractionEnabled:)]];
			[inv setSelector:@selector(setUserInteractionEnabled:)];
			[inv setTarget:_closeButton];
			[inv setArgument:&_closeButtonVisible atIndex:2];
			[inv performSelector:@selector(invoke) withObject:nil afterDelay:(0.5)];
		}
		
		if ([name isEqualToString:MG_ANIMATION_TILES]) {
			layer = [animation valueForKey:MG_ANIMATION_TILE_LAYER];
			NSInteger lastAnimatedTileIndex = [[_animationOrder lastObject] integerValue];
			if (_tilesArranged) {
				// Tile animations finished at centre; mark as unarranged and continue.
				// Only continue to second part of animation after the last tile has finished its first part.
				if ([[animation valueForKey:MG_ANIMATION_TILE_INDEX] integerValue] == lastAnimatedTileIndex) {
					_tilesArranged = NO;
					continueAnimation = YES;
				}
			} else {
				// Tile animations finished at final positions; mark as arranged.
				if ([[animation valueForKey:MG_ANIMATION_TILE_INDEX] integerValue] == lastAnimatedTileIndex) {
					_tilesArranged = YES;
					_animatingTiles = NO;
					[self setAllTilesInteractionEnabled:YES];
					UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
					
					// Inform delegate.
					if (_delegate && [_delegate respondsToSelector:@selector(tileMenu:didSwitchToPage:)]) {
						[_delegate tileMenu:self didSwitchToPage:_currentPage];
					}
					
					// Send notification.
					NSDictionary *info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:_currentPage] 
																	 forKey:MGPageNumberKey];
					[[NSNotificationCenter defaultCenter] postNotificationName:MGTileMenuDidSwitchToPageNotification 
																		object:self 
																	  userInfo:info];
				}
			}
		}
		
		// Commit animation's final state and remove it.
		if ([animation isKindOfClass:[CABasicAnimation class]]) {
			path = [(CABasicAnimation *)animation keyPath];
			if (cleanUp) {
				fromValue = [(CABasicAnimation *)animation fromValue];
			} else {
				[layer setValue:[(CABasicAnimation *)animation toValue] forKeyPath:path];
			}
			[layer removeAnimationForKey:path];
		}
	}
	
	if (cleanUp) {
		// Remove from spawning view.
		[self.view removeFromSuperview];
		UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
		
		// Inform delegate.
		if (_appeared && _delegate && [_delegate respondsToSelector:@selector(tileMenuDidDismiss:)]) {
			[_delegate tileMenuDidDismiss:self];
		}
		
		// Send notification.
		[[NSNotificationCenter defaultCenter] postNotificationName:MGTileMenuDidDismissNotification 
															object:self 
														  userInfo:nil];
		
		_appeared = NO;
		
		if (path && fromValue) {
			[layer setValue:fromValue forKeyPath:path];
		}
		for (UIButton *tileButton in _tileButtons) {
			tileButton.frame = [self frameForCenteredTile];
		}
	}
	
	if (continueAnimation) {
		[self animateTilesForCurrentPage];
	}
}


- (void)animateTilesForCurrentPage
{
	// Determine which animation (to or from centre) to perform.
	CGPoint centrePoint = MGCenterPoint([self frameForCenteredTile]);
	CGPoint tileCentre;
	CABasicAnimation *tileAnimation;
	UIButton *tile;
	CFTimeInterval baseTime = CACurrentMediaTime();
	CFTimeInterval delay = (_appeared) ? 0 : MG_ANIMATION_DURATION; // allow for menu appearance animation
	CFTimeInterval duration = (_tilesArranged) ? MG_ANIMATION_DURATION - 0.05 : MG_ANIMATION_DURATION; // go to centre quicker than going back out
	CFTimeInterval offset = (_tilesArranged) ? 0.05 : 0.1; // go to centre quicker than going back out
	
	
	// Use delegate methods to configure tiles, showing/hiding as required, if we're at the centre.
	if (!_tilesArranged) {
		NSInteger numTiles = 0;
		if (_delegate && [_delegate respondsToSelector:@selector(numberOfTilesInMenu:)]) {
			numTiles = MAX(0, [_delegate numberOfTilesInMenu:self]);
		}
		NSInteger numPages = MAX(1, ceil((double)numTiles / (double)MG_TILES_PER_PAGE));
		if (_singlePageMaxTiles) {
			numPages = 1;
		}
		_pageButton.hidden = (numPages <= 1);
		if (self.currentPage >= numPages) {
			_currentPage = numPages - 1;
		}
		if (self.currentPage < 0) {
			_currentPage = 0;
		}
		_pageButton.accessibilityLabel = NSLocalizedString(@"Next page", @"Accessibility label for page-switching button");
		_pageButton.accessibilityHint = [NSString stringWithFormat:@"%@ (%@ %d %@ %d)",
										  NSLocalizedString(@"Switches to next page of buttons", @"Accessibility hint for page-switching button"),
										  NSLocalizedString(@"page", nil),
										  _currentPage + 1,
										  NSLocalizedString(@"of", nil),
										  numPages];
		
		// Work out number of tiles that are visible
		NSInteger numVisibleTiles = MIN(MG_TILES_PER_PAGE, numTiles - (_currentPage * MG_TILES_PER_PAGE));
		if (_singlePageMaxTiles) {
			numVisibleTiles++;
		}
		NSInteger firstTileIndex = _currentPage * MG_TILES_PER_PAGE;
		
		// Configure needed tiles, hiding/showing as appropriate.
		NSInteger i = 0;
		NSInteger currentTileIndex;
		UIImage *tileImage;
		BOOL tileEnabled = YES;
		BOOL shouldHide = NO;
		for (UIButton *tileButton in _tileButtons) {
			currentTileIndex = (firstTileIndex + i);
			shouldHide = (i > (numVisibleTiles - 1));
			if (shouldHide) {
				[tileButton setImage:nil forState:UIControlStateNormal];
				[tileButton setImage:nil forState:UIControlStateHighlighted];
				[tileButton setBackgroundImage:nil forState:UIControlStateNormal];
				[tileButton setBackgroundImage:nil forState:UIControlStateHighlighted];
				[tileButton setAccessibilityLabel:nil];
				[tileButton setAccessibilityHint:nil];
				tileButton.alpha = 1.0;
				
				[UIView transitionWithView:tileButton 
								  duration:MG_ANIMATION_DURATION 
								   options:UIViewAnimationOptionTransitionCrossDissolve 
								animations:^{
									tileButton.alpha = 0.0;
								}
								completion:NULL];
				
			} else {
				tileImage = [_delegate imageForTile:currentTileIndex inMenu:self];
				[tileButton setImage:tileImage forState:UIControlStateNormal];
				[tileButton setImage:tileImage forState:UIControlStateHighlighted];
				[tileButton setBackgroundImage:[self tileBackgroundImageForTile:currentTileIndex highlighted:NO] 
									  forState:UIControlStateNormal];
				[tileButton setBackgroundImage:[self tileBackgroundImageForTile:currentTileIndex highlighted:YES] 
									  forState:UIControlStateHighlighted];
				[tileButton setAccessibilityLabel:[_delegate labelForTile:currentTileIndex inMenu:self]];
				[tileButton setAccessibilityHint:[_delegate descriptionForTile:currentTileIndex inMenu:self]];
				if (_delegate && [_delegate respondsToSelector:@selector(isTileEnabled:inMenu:)]) {
					tileEnabled = [_delegate isTileEnabled:currentTileIndex inMenu:self];
				}
				tileButton.alpha = ((tileEnabled) ? 1.0 : MG_DISABLED_TILE_OPACITY);
				
				if (_appeared) {
					[UIView transitionWithView:tileButton 
									  duration:MG_ANIMATION_DURATION 
									   options:UIViewAnimationOptionTransitionCrossDissolve 
									animations:^{
										tileButton.imageView.image = tileImage;
									}
									completion:NULL];
				}
			}
			
			i++;
		}
	}
	
	NSInteger j;
	NSInteger numAnimatedTiles = _tileButtons.count;
	for (int i = 0; i < numAnimatedTiles; i++) {
		j = [[_animationOrder objectAtIndex:i] integerValue];
		if (j >= [_tileButtons count]) {
			break;
		}
		tile = [_tileButtons objectAtIndex:j];
		tileAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
		tileAnimation.beginTime = baseTime + delay + ((CGFloat)i * offset);
		[tileAnimation setValue:MG_ANIMATION_TILES forKey:@"name"];
		[tileAnimation setRemovedOnCompletion:NO];
		[tileAnimation setDuration:duration];
		[tileAnimation setFillMode:kCAFillModeForwards];
		[tileAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
		tileCentre = MGCenterPoint([self frameForTileAtIndex:j]);
		
		CALayer *presentationLayer = (CALayer *)[tile.layer presentationLayer];
		CGPoint currentPosition = presentationLayer.position;
		
		if (!_tilesArranged) {
			// We're going from the centre out towards the final position.
			tileAnimation.fromValue = [NSValue valueWithCGPoint:(_tileAnimationInterrupted) ? currentPosition : centrePoint];
			tileAnimation.toValue = [NSValue valueWithCGPoint:tileCentre];
		} else {
			// We're going from the initial position in towards the centre.
			tileAnimation.fromValue = [NSValue valueWithCGPoint:(_tileAnimationInterrupted) ? currentPosition : tileCentre];
			tileAnimation.toValue = [NSValue valueWithCGPoint:centrePoint];
		}
		[tileAnimation setDelegate:self];
		[tileAnimation setValue:tile.layer forKey:MG_ANIMATION_TILE_LAYER];
		[tileAnimation setValue:[NSNumber numberWithInteger:j] forKey:MG_ANIMATION_TILE_INDEX];
		[tile.layer addAnimation:tileAnimation forKey:MG_ANIMATION_TILES];
	}
	
	_tileAnimationInterrupted = NO;
}


- (void)setAllTilesInteractionEnabled:(BOOL)enabled
{
	_pageButton.userInteractionEnabled = enabled;
	NSInteger tileIndex = _currentPage * MG_TILES_PER_PAGE;
	BOOL askDelegate = enabled && (_delegate && [_delegate respondsToSelector:@selector(isTileEnabled:inMenu:)]);
	
	for (UIButton *tileButton in _tileButtons) {
		if (askDelegate) {
			tileButton.userInteractionEnabled = [_delegate isTileEnabled:tileIndex inMenu:self];
		} else {
			tileButton.userInteractionEnabled = enabled;
		}
		
		tileIndex++;
	}
}


#pragma mark - Managing pages of tiles


- (void)switchToPage:(NSInteger)pageNum
{
	pageNum = [self nextPageNumber:pageNum - 1];
	_currentPage = pageNum;
	
	// Inform delegate.
	if (_delegate && [_delegate respondsToSelector:@selector(tileMenu:willSwitchToPage:)]) {
		[_delegate tileMenu:self willSwitchToPage:_currentPage];
	}
	
	// Send notification.
	NSDictionary *info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:_currentPage] 
													 forKey:MGPageNumberKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGTileMenuWillSwitchToPageNotification 
														object:self 
													  userInfo:info];
	
	// Begin an appropriate tile-animation.
	_pageButton.userInteractionEnabled = NO;
	[self setAllTilesInteractionEnabled:NO];
	if (_animatingTiles) {
		_tileAnimationInterrupted = YES;
		for (UIButton *tileButton in _tileButtons) {
			[tileButton.layer removeAllAnimations];
			CALayer *presentationLayer = (CALayer *)[tileButton.layer presentationLayer];
			tileButton.frame = presentationLayer.frame;
		}
	}
	_animatingTiles = YES;
	[self animateTilesForCurrentPage];
}


- (void)goToNextPage
{
	// Check with delegate.
	BOOL shouldSwitch = YES;
	NSInteger newPage = [self nextPageNumber:_currentPage];
	if (_delegate && [_delegate respondsToSelector:@selector(tileMenu:shouldSwitchToPage:)]) {
		shouldSwitch = [_delegate tileMenu:self shouldSwitchToPage:newPage];
	}
	
	if (shouldSwitch) {
		[self switchToPage:newPage];
	}
}


@end
