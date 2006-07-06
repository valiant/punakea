//
//  PAImageButton.m
//  punakea
//
//  Created by Daniel on 23.03.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PAImageButton.h"


@implementation PAImageButton

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		PAImageButtonCell *cell = [[PAImageButtonCell alloc] initImageCell:nil];
		[self setCell:cell];
		[cell release];
		tag = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setImage:(NSImage *)anImage forState:(PAImageButtonState)aState
{
	[[self cell] setImage:anImage forState:aState];
}

- (void)setButtonType:(PAImageButtonType)aType
{
	[[self cell] setButtonType:aType];
}

- (BOOL)isHighlighted
{
	return [[self cell] isHighlighted];
}

- (void)dealloc
{
	if(tag) [tag release];
	[super dealloc];
}


#pragma mark Accessors
- (PAImageButtonState)state
{
	return [[self cell] state];
}

- (void)setState:(PAImageButtonState)aState
{
	[[self cell] setState:aState];
}

- (NSMutableDictionary *)tag
{
	return tag;
}

- (void)setTag:(NSMutableDictionary *)aTag
{
	tag = [aTag retain];
}
@end