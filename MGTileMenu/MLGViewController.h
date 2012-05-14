//
//  MLGViewController.h
//  MGTileMenu
//
//  Created by Matt Gemmell on 27/01/2012.
//  Copyright (c) 2012 Instinctive Code.
//

#import <UIKit/UIKit.h>
#import "MGTileMenuController.h"

@interface MLGViewController : UIViewController <MGTileMenuDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) MGTileMenuController *tileController;

@end
