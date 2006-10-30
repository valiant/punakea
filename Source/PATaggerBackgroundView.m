//
//  PATaggerBackgroundView.m
//  punakea
//
//  Created by Daniel on 26.10.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PATaggerBackgroundView.h"


@implementation PATaggerBackgroundView

#pragma mark Init + Dealloc
- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if(self)
	{
		// nothing yet
	}	
	return self;
}

- (void)dealloc
{
	if(addButton) [addButton release];
	if(removeButton) [removeButton release];
	[super dealloc];
}


#pragma mark Drawing
- (void)drawRect:(NSRect)aRect
{	
	aRect = [self bounds];

	[[NSColor clearColor] set];
	NSBezierPath *path = [NSBezierPath bezierPathWithRect:aRect];
	[path fill];

	CTGradient *gradient = [CTGradient unifiedSelectedGradient];
	[gradient fillRect:aRect angle:90.0];
	
	// Draw fake bar
	NSImage *image = [NSImage imageNamed:@"statusbar.tiff"];
	[image setScalesWhenResized:YES];
	
	NSRect imageRect;
	imageRect.origin = NSZeroPoint;
	imageRect.size = [image size];
	
	NSRect rect = aRect;
	rect.size.height = 23;
	
	[image drawInRect:rect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
	
	// Draw addButton
	if(!addButton)
	{
		NSRect rect;
		rect.origin = NSZeroPoint;
		rect.size.width = 28;
		rect.size.height = 23;
	
		addButton = [[PAImageButton alloc] initWithFrame:rect];
		[addButton setImage:[NSImage imageNamed:@"Add"] forState:PAOffState];
		[addButton setImage:[NSImage imageNamed:@"AddPressed"] forState:PAOnState];
		[addButton setState:PAOffState];
		
		[addButton setAction:@selector(addButtonClicked:)];
		[addButton setTarget:controller];

		[self addSubview:addButton]; 
	}
	
	// Draw removeButton
	if(!removeButton)
	{
		NSRect rect;
		rect.origin.x = 27;  // As both buttons have borders, overlap them by 1px
		rect.origin.y = 0;
		rect.size.width = 28;
		rect.size.height = 23;
	
		removeButton = [[PAImageButton alloc] initWithFrame:rect];
		[removeButton setImage:[NSImage imageNamed:@"Remove"] forState:PAOffState];
		[removeButton setImage:[NSImage imageNamed:@"RemovePressed"] forState:PAOnState];
		[removeButton setState:PAOffState];
		
		[removeButton setAction:@selector(removeButtonClicked:)];
		[removeButton setTarget:controller];

		[self addSubview:removeButton]; 
	}
}

@end
