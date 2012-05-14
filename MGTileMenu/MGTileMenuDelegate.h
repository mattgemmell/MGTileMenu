//
//  MGTileMenuDelegate.h
//  MGTileMenu
//
//  Created by Matt Gemmell on 28/01/2012.
//  Copyright (c) 2012 Instinctive Code.
//

#ifndef MGTileMenu_MGTileMenuDelegate_h
#define MGTileMenu_MGTileMenuDelegate_h
#endif

#define MG_PAGE_SWITCHING_TILE_INDEX -1

@class MGTileMenuController;
@protocol MGTileMenuDelegate <NSObject>

// Configuration
@required
- (NSInteger)numberOfTilesInMenu:(MGTileMenuController *)tileMenu; // in total (will shown in groups of up to 5 per page)
- (UIImage *)imageForTile:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu; // zero-based tileNumber
- (NSString *)labelForTile:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu; // zero-based tileNumber
- (NSString *)descriptionForTile:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu; // zero-based tileNumber
// N.B. Labels and descriptions (hints) are used for accessibility, and are thus required. They are not displayed.
// N.B. Images are centered on the tile, and are not scaled.
@optional
- (BOOL)isTileEnabled:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu; // zero-based tileNumber

// Tile backgrounds.
@optional
- (UIImage *)backgroundImageForTile:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu; // zero-based tileNumber
- (CGGradientRef)gradientForTile:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu; // zero-based tileNumber
- (UIColor *)colorForTile:(NSInteger)tileNumber inMenu:(MGTileMenuController *)tileMenu; // zero-based tileNumber
// N.B. Background images take precedence over gradients, which take precedence over flat colors. Only one will be rendered.
//      Background images are scaled (non-proportionately, so it's best to supply square images) to fit the tile.
//      If none of the above three methods are implemented, or don't return valid data, tiles be rendered with the menu's tileGradient.
//      In all cases, the tiles' backgrounds will be clipped to a rounded rectangle.
//      Note that these methods are also called for the page-switching tile, with tileNumber MG_PAGE_SWITCHING_TILE_INDEX.

// Interaction/notification
@required
- (void)tileMenu:(MGTileMenuController *)tileMenu didActivateTile:(NSInteger)tileNumber; // zero-based tileNumber
// N.B. The above method fires when the user has pressed and released a given tile, thus choosing or activating it.

@optional
- (void)tileMenuWillDisplay:(MGTileMenuController *)tileMenu;
- (void)tileMenuDidDisplay:(MGTileMenuController *)tileMenu;

- (BOOL)tileMenuShouldDismiss:(MGTileMenuController *)tileMenu;
- (void)tileMenuWillDismiss:(MGTileMenuController *)tileMenu;
- (void)tileMenuDidDismiss:(MGTileMenuController *)tileMenu;

- (void)tileMenu:(MGTileMenuController *)tileMenu didSelectTile:(NSInteger)tileNumber; // zero-based tileNumber
- (void)tileMenu:(MGTileMenuController *)tileMenu didDeselectTile:(NSInteger)tileNumber; // zero-based tileNumber

- (BOOL)tileMenu:(MGTileMenuController *)tileMenu shouldSwitchToPage:(NSInteger)pageNumber; // zero-based pageNumber
- (void)tileMenu:(MGTileMenuController *)tileMenu willSwitchToPage:(NSInteger)pageNumber; // zero-based pageNumber
- (void)tileMenu:(MGTileMenuController *)tileMenu didSwitchToPage:(NSInteger)pageNumber; // zero-based pageNumber

@end
