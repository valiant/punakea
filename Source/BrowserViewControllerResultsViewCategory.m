//
//  BrowserViewControllerResultsViewCategory.m
//  punakea
//
//  Created by Daniel on 06.07.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BrowserViewControllerResultsViewCategory.h"


@implementation BrowserViewController (ResultsViewCategory)

#pragma mark Data Source
- (id)          outlineView:(NSOutlineView *)ov 
  objectValueForTableColumn:(NSTableColumn *)tableColumn
					 byItem:(id)item
{
	return item;
	
	/*if([item isKindOfClass:[PAQueryBundle class]])
		return item;
	else 
		return [item valueForAttribute:@"value"];*/
}

- (id)outlineView:(NSOutlineView *)ov child:(int)index ofItem:(id)item
{		
	if(item == nil)
	{
		// Children depend on display mode		
		if([outlineView displayMode] == PAThumbnailMode)
		{
			return [query results];
		}
	
		return [query resultAtIndex:index];
	}
	
	if([item isKindOfClass:[PAQueryBundle class]])
	{
		PAQueryBundle *bundle = item;
		
		// Children depend on display mode		
		if([outlineView displayMode] == PAThumbnailMode)
		{
			return [bundle results];
		}
			
		//NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		//NSDictionary *currentDisplayModes = [[defaults objectForKey:@"Results"] objectForKey:@"CurrentDisplayModes"];
		
		/*if([[currentDisplayModes objectForKey:[group value]] isEqualToString:@"IconMode"]) */

		return [bundle resultAtIndex:index];
	}
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
	if(item == nil) return YES;

	return ([self outlineView:ov numberOfChildrenOfItem:item] != 0);
}

- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item
{
	if(item == nil)
	{
		// Number of children depends on display mode
		if([outlineView displayMode] == PAThumbnailMode) return 1;
			
		return [query resultCount];
	}
	
	if([item isKindOfClass:[PAQueryBundle class]])
	{
		PAQueryBundle *bundle = item;
		
		// Number of children depends on display mode
		if([outlineView displayMode] == PAThumbnailMode) return 1;
			
		/*NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary *currentDisplayModes = [[defaults objectForKey:@"Results"] objectForKey:@"CurrentDisplayModes"];
		
		if([[currentDisplayModes objectForKey:[bundle value]] isEqualToString:@"IconMode"])
			return 1;*/
		
		return [bundle resultCount];
	}
	
	return 0;
}


#pragma mark Set Object Value
- (void)outlineView:(NSOutlineView *)ov
     setObjectValue:(id)object
	 forTableColumn:(NSTableColumn *)tableColumn
	         byItem:(id)item
{
	PAQueryItem *queryItem = item;
	NSString *value = object;
	
	PAFile *file = [PAFile fileWithPath:[queryItem valueForAttribute:(id)kMDItemPath]];
	
	NSString *source = [file path];
	NSString *destination = [file directory];
	destination = [destination stringByAppendingPathComponent:value];
	
	// Return if source equals destination
	if([source isEqualToString:destination]) return;
	
	// TODO: Add error handler
	BOOL fileWasMoved = [[NSFileManager defaultManager] movePath:source toPath:destination handler:self];
	
	// TODO: Currently we set the displayName + path by hand in the following lines. Maybe we can
	// do this with a query update automatically...
	if(fileWasMoved)
	{
		[item setValue:value forAttribute:(id)kMDItemDisplayName];
		[item setValue:destination forAttribute:(id)kMDItemPath];
	
		[ov reloadItem:item];
	}
}

- (void)fileManager:(NSFileManager *)manager willProcessPath:(NSString *)path
{
	// nothing yet
}

-(BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorInfo
{
	NSString *informativeText;
	informativeText = [NSString stringWithFormat:
			NSLocalizedStringFromTable(@"ALREADY_EXISTS_INFORMATION", @"FileManager", @""),
			[errorInfo objectForKey:@"ToPath"]];

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];

	// TODO: Support correct error message text for more types of errors
	if([[errorInfo objectForKey:@"Error"] isEqualTo:@"Already Exists"])
	{
		[alert setMessageText:NSLocalizedStringFromTable([errorInfo objectForKey:@"Error"], @"FileManager", @"")];
		[alert setInformativeText:informativeText];
	} else {
		[alert setMessageText:NSLocalizedStringFromTable(@"Unknown Error", @"FileManager", @"")];
	}

	[alert addButtonWithTitle:@"OK"];
	[alert setAlertStyle:NSWarningAlertStyle];  
	
	[alert beginSheetModalForWindow:[outlineView window]
	                  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
					    contextInfo:nil];
						
	return NO;
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	// nothing yet
}


#pragma mark Delegate
- (float)outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item
{		
	if([item isKindOfClass:[PAQueryBundle class]]) return 20.0;
	if([item isKindOfClass:[PAQueryItem class]]) return 19.0;
	
	// TEMP
	//return 200.0;
	
	// Get height of multi item dynamically	from outlineview
	
	Class cellClass = [PAResultsMultiItemPlaceholderCell class];
	switch([outlineView displayMode])
	{
		case PAThumbnailMode:
			cellClass = [PAResultsMultiItemThumbnailCell class]; break;
	}
	
	NSSize cellSize = [cellClass cellSize];
	NSSize intercellSpacing = [cellClass intercellSpacing];
	float indentationPerLevel = [outlineView indentationPerLevel];
	float offsetToRightBorder = 20.0;
	NSRect frame = [outlineView frame];

	int numberOfItemsPerRow = (frame.size.width - indentationPerLevel - offsetToRightBorder) /
	                          (cellSize.width + intercellSpacing.width);

	int numberOfRows = [item count] / numberOfItemsPerRow;
	if([item count] % numberOfItemsPerRow > 0) numberOfRows++;
	
	int result = numberOfRows * (cellSize.height + intercellSpacing.height);
	if(result == 0) result = 1;

	return result;
}

- (id)tableColumn:(NSTableColumn *)column
	  inTableView:(NSTableView *)tableView
   dataCellForRow:(int)row
{
	NSOutlineView *ov = (NSOutlineView *)tableView;
	id item = [ov itemAtRow:row];
	
	NSCell *cell;	
	if([item isKindOfClass:[PAQueryBundle class]])
	{
		cell = [[[PAResultsGroupCell alloc] initTextCell:@""] autorelease];
	}
	else if([item isKindOfClass:[PAQueryItem class]])
	{
		cell = [[[PAResultsItemCell alloc] initTextCell:@""] autorelease];
		[cell setEditable:YES];
	}
	else 
	{
		cell = [[[PAResultsMultiItemCell alloc] initTextCell:@""] autorelease];
	}		

	return cell;
}

- (void)     outlineView:(NSOutlineView *)ov
  willDisplayOutlineCell:(id)cell
	      forTableColumn:(NSTableColumn *)tableColumn
                    item:(id)item
{
	// Hide default triangle
	[cell setImage:[NSImage imageNamed:@"transparent"]];
	[cell setAlternateImage:[NSImage imageNamed:@"transparent"]];
}

- (void)outlineView:(NSOutlineView *)outlineView
	willDisplayCell:(id)cell
	 forTableColumn:(NSTableColumn *)tableColumn
	           item:(id)item
{
	/*if([item isKindOfClass:[NSMetadataQueryResultGroup class]])
	{
		[cell setObjectValue:item];
		NSLog([item value]);
	}*/
	//if([[item class] isEqualTo:[NSMetadataItem class]])
	//	[(PAResultsItemCell *)cell setItem:(NSMetadataItem *)item];
	
	// TODO Replace this by setObjectValue
	/*if([[item class] isEqualTo:[PAResultsMultiItem class]])
		[(PAResultsMultiItemCell *)cell setItem:(PAResultsMultiItem *)item];*/
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	//NSMetadataQueryResultGroup *item = (NSMetadataQueryResultGroup *)[[notification userInfo] objectForKey:@"NSObject"];
	//[self removeAllMultiItemSubviewsWithIdentifier:[item value]];
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item
{
	// Resign any matrix from being responder
	if(![item isKindOfClass:[NSArray class]])
	{
		[outlineView setResponder:nil];
	}

	return [item isKindOfClass:[PAQueryBundle class]] ? NO : YES;
}


#pragma mark Actions
- (void)triangleClicked:(id)sender
{
	PAQueryBundle *item = [(NSDictionary *)[sender tag] objectForKey:@"bundle"];

	if([outlineView isItemExpanded:item])
	{
		// Just toggle the item's state
		[outlineView collapseItem:item];
	} else {
		// If we expand an item, we need to redraw all previously visible rows so that they
		// can correctly (re-)move their subviews
		
		NSRange previousVisibleRowsRange = [outlineView rowsInRect:[outlineView visibleRect]];
		
		[outlineView expandItem:item];
		
		int numberOfChildrenOfItem = [[outlineView delegate] outlineView:outlineView numberOfChildrenOfItem:item];
		for(unsigned i = 0; i < previousVisibleRowsRange.length; i++)
		{
			[outlineView drawRow:(numberOfChildrenOfItem + previousVisibleRowsRange.location + i) clipRect:[outlineView bounds]];
		}
	}
	
	// Save userDefaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *results = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:@"Results"]];
	NSMutableArray *collapsedGroups = [NSMutableArray arrayWithArray:[results objectForKey:@"CollapsedGroups"]];
	
	if([outlineView isItemExpanded:item])
		[collapsedGroups removeObject:[item value]];
	else
		[collapsedGroups addObject:[item value]];
			
	[results setObject:collapsedGroups forKey:@"CollapsedGroups"];		
	[defaults setObject:results forKey:@"Results"];
}

- (void)segmentedControlClicked:(id)sender
{
	NSString *identifier = [(NSDictionary *)[sender tag] objectForKey:@"identifier"];
	NSMetadataQueryResultGroup *item = [outlineView groupForIdentifier:identifier];
	NSString *mode = [[(PAImageButtonCell *)[(PASegmentedImageControl *)sender selectedCell] tag] objectForKey:@"identifier"];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// Ignore this click if this state was already active
	if([mode isNotEqualTo:
			  [[[defaults objectForKey:@"Results"]
				          objectForKey:@"CurrentDisplayModes"]
						  objectForKey:[item value]]])
	{
		// Save userDefaults
		NSMutableDictionary *results = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:@"Results"]];
		NSMutableDictionary *currentDisplayModes = [NSMutableDictionary dictionaryWithDictionary:[results objectForKey:@"CurrentDisplayModes"]];
		[currentDisplayModes setObject:mode forKey:[item value]];	
		[results setObject:currentDisplayModes forKey:@"CurrentDisplayModes"];	
		[defaults setObject:results forKey:@"Results"];
		
		// TODO: Remember selected items
		/*NSMutableIndexSet *selectedIndexes = [NSMutableIndexSet indexSet];
		if([outlineView isItemExpanded:item])
		{
			int row = [outlineView rowForItem:item] + 1;
			if([[[outlineView itemAtRow:row] class] isEqualTo:[PAResultsMultiItem class]])
			{
				
			} else {
				int level = [outlineView levelForItem:item];
				NSIndexSet *indexSet = [outlineView selectedRowIndexes];
				while([outlineView levelForRow:row] == level)
				{
					if([indexSet containsIndex:row])
						[selectedIndexes addIndex:row];
					row++;
				}
			}
			NSLog(identifier);
		}*/
		
		// Refresh the group's display
		[outlineView reloadItem:item reloadChildren:YES];
		[self removeAllMultiItemSubviewsWithIdentifier:[item value]];
		//[outlineView setNeedsDisplay];
		
		// TODO: Restore selection
		/*for(int i = 0; i < [selectedIndexes count]; i++)
		{
			
		}*/
	}
}

- (IBAction)doubleAction:(id)sender
{
	NSIndexSet *selectedRowIndexes = [outlineView selectedRowIndexes];	
	unsigned row = [selectedRowIndexes firstIndex];
	while(row != NSNotFound) 
	{
		id item = [outlineView itemAtRow:row];
		
		// TODO: If item is MultiItem, get selected cells and process them
		if([[item class] isEqualTo:[PAQueryItem class]])
		{
			[[NSWorkspace sharedWorkspace] openFile:[item valueForAttribute:(id)kMDItemPath]];
		}
		
		row = [selectedRowIndexes indexGreaterThanIndex:row];
	}
}

- (void)removeAllMultiItemSubviewsWithIdentifier:(NSString *)identifier
{
	NSLog(@"removing subviews commented");
	/*NSEnumerator *enumerator = [[outlineView subviews] objectEnumerator];
	id anObject;
	while(anObject = [enumerator nextObject])
	{
		if([[anObject class] isEqualTo:[PAResultsMultiItemMatrix class]])
		{
			PAResultsMultiItem *theseItems = [(PAResultsMultiItemMatrix *)anObject items];
			NSString *thisIdentifier = [[thisItem tag] objectForKey:@"identifier"];
			if([identifier isEqualToString:thisIdentifier])
				[anObject removeFromSuperview];
		}
	}*/
}

- (void)hideAllSubviews
{
	NSEnumerator *enumerator = [[outlineView subviews] objectEnumerator];
	id anObject;
	while(anObject = [enumerator nextObject])
	{
		[anObject setHidden:YES];
	}
}

@end
