//
//  PASelectedTagsView.h
//  punakea
//
//  Created by Johannes Hoffart on 31.03.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAFilterSlice.h"
#import "PAResultsOutlineView.h"
#import "PAResultsViewController.h"
#import "PATag.h"
#import "PASelectedTags.h"
#import "PAButton.h"

extern NSSize const PADDING;
extern NSSize const INTERCELL_SPACING;
extern int const PADDING_TO_RIGHT;

@interface PASelectedTagsView : NSView {
	
	IBOutlet PAResultsOutlineView		*outlineView;
	IBOutlet PAFilterSlice				*filterSlice;
	IBOutlet PAResultsViewController	*controller;
	PASelectedTags						*selectedTags;
	
	NSMutableDictionary					*tagButtons;
	
	BOOL								ignoreFrameDidChange;
	
}

@end
