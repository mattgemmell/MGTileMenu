//
//  MGTileMenuView.m
//  MGTileMenu
//
//  Created by Matt Gemmell on 03/02/2012.
//  Copyright (c) 2012 Instinctive Code.
//

#import "MGTileMenuView.h"
#import <QuartzCore/QuartzCore.h>


@implementation MGTileMenuView


@synthesize controller;


- (void)drawRect:(CGRect)rect
{
    // It's tough being this good, but somehow I manage.
	[controller.bezelColor set];
	[[controller _bezelPath] fill];
}


@end
