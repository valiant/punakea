//
//  PAQuery.m
//  punakea
//
//  Created by Daniel on 21.05.06.
//  Copyright 2006 nudge:nudge. All rights reserved.
//

#import "PAQuery.h"

NSString * const PAQueryDidStartGatheringNotification = @"PAQueryDidStartGatheringNotification";
NSString * const PAQueryGatheringProgressNotification = @"PAQueryGatheringProgressNotification";
NSString * const PAQueryDidUpdateNotification = @"PAQueryDidUpdateNotification";
NSString * const PAQueryDidFinishGatheringNotification = @"PAQueryDidFinishGatheringNotification";
NSString * const PAQueryDidResetNotification = @"PAQueryDidResetNotification";

//NSString * const PAQueryGroupingAttributesDidChange = @"PAQueryGroupingAttributesDidChange";

@interface PAQuery (PrivateAPI)

- (void)tagsHaveChanged:(NSNotification *)note;
- (void)updateQueryFromTags;
- (NSString*)queryStringForTags:(NSArray*)tags;
- (NSString*)queryInSpotlightSyntaxForTags:(NSArray*)someTags;

- (NSPredicate *)predicate;
- (void)setPredicate:(NSPredicate *)aPredicate;

- (NSArray *)filteredResults;
- (void)setFilteredResults:(NSMutableArray *)newResults;
- (NSArray *)flatFilteredResults;
- (void)setFlatFilteredResults:(NSMutableArray *)newResults;

- (void)createQuery;
- (void)setMdquery:(NSMetadataQuery*)query;

- (void)synchronizeResults;
- (NSMutableArray *)bundleResults:(NSArray *)theResults byAttributes:(NSArray *)attributes;
- (void)filterResults:(BOOL)flag usingValues:(NSArray *)filterValues forBundlingAttribute:(NSString *)attribute newBundlingAttributes:(NSArray *)newAttributes;

- (void)setDelegate:(id)aDelegate;

@end 

@implementation PAQuery

#pragma mark Init + Dealloc
- (id)init
{
	return [self initWithTags:[[[PASelectedTags alloc] init] autorelease]];
}

- (id)initWithTags:(PASelectedTags*)otherTags
{
	if (self = [super init])
	{		
		[self setDelegate:self];
		[self createQuery];
		
		[self setTags:otherTags];
	}
	return self;
}

- (void)dealloc
{
	[tags release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if ([self isStarted]) [self stopQuery];	
	[mdquery release];
	[bundlingAttributes release];
	[filterDict release];
	[predicate release];
	[super dealloc];
}

#pragma mark Actions
- (void)createQuery
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	
	[self setMdquery:[[[NSMetadataQuery alloc] init] autorelease]];
	[mdquery setDelegate:self];
	[mdquery setNotificationBatchingInterval:0.3];
	[mdquery setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemFSName ascending:YES] autorelease]]];
	
	[nc addObserver:self
		   selector:@selector(metadataQueryNote:)
			   name:nil
			 object:mdquery];
	
	[self setFlatResults:[NSMutableArray array]];
	
	[self synchronizeResults];
	
	[nc postNotificationName:PAQueryDidResetNotification object:self];
}

- (void)setMdquery:(NSMetadataQuery*)query
{
	[query retain];
	[mdquery release];
	mdquery = query;
}

- (BOOL)startQuery
{
	// Cleanup results
	[self setFlatResults:[NSMutableArray array]];
	[self setResults:[NSMutableArray array]];
	[self setFlatFilteredResults:[NSMutableArray array]];
	[self setFilteredResults:[NSMutableArray array]];
	
	// Finally, post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:PAQueryDidStartGatheringNotification
														object:self];
	
	return [mdquery startQuery];
}

- (void)stopQuery
{
	// TODO
	
	// Finally, post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:PAQueryDidFinishGatheringNotification
														object:self];
}

- (void)disableUpdates
{
	[mdquery disableUpdates];
}

- (void)enableUpdates
{
	[mdquery enableUpdates];
}

/**
	Synchronizes results of MetadataQuery
    @returns Dictionary with added/removed/updated items
*/
- (NSDictionary *)synchronizeResults
{
	[self disableUpdates];

	// We don't use [mdquery results] as this proxy array causes missing results during live update
	NSMutableArray *mdQueryResults = [NSMutableArray array];
	for(unsigned i = 0; i < [mdquery resultCount]; i++)
	{
		NSMetadataItem *mdItem = [mdquery resultAtIndex:i];
		
		if([[NSFileManager defaultManager] fileExistsAtPath:[mdItem valueForAttribute:(id)kMDItemPath]]) {
			[mdQueryResults addObject:mdItem];
		}
	}
	
	NSArray *newFlatResults = [self bundleResults:mdQueryResults byAttributes:nil];
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	
	NSMutableArray *theFlatResults = [self flatResults];
	if(theFlatResults && [theFlatResults count] > 0)
	{
		// There are already some results
		
		NSMutableArray *userInfoAddedItems = [NSMutableArray array];
		NSMutableArray *userInfoRemovedItems = [NSMutableArray array];
		
		// First, match new to old results
		NSEnumerator *enumerator = [newFlatResults objectEnumerator];
		PAFile *newResultItem;
		while(newResultItem = [enumerator nextObject])
		{
			if(![theFlatResults containsObject:newResultItem])
			{
				[userInfoAddedItems addObject:newResultItem];
			}
		}
		
		// Next, match vice-versa
		enumerator = [theFlatResults objectEnumerator];
		PAFile *oldResultItem;
		while(oldResultItem = [enumerator nextObject])
		{
			if(![newFlatResults containsObject:oldResultItem])
			{
				[userInfoRemovedItems addObject:oldResultItem];
			}
		}
		
		// Currently, this does not note if an item was modified - only removing and adding
		// of items will be passed in userInfo
		[userInfo setObject:userInfoAddedItems forKey:(id)kMDQueryUpdateAddedItems];
		[userInfo setObject:userInfoRemovedItems forKey:(id)kMDQueryUpdateRemovedItems];
		
		[theFlatResults addObjectsFromArray:userInfoAddedItems];
		[theFlatResults removeObjectsInArray:userInfoRemovedItems];
	}	
	else 
	{
		[self setFlatResults:newFlatResults];
	}
	
	[self setResults:[self bundleResults:[self flatResults] byAttributes:bundlingAttributes]];	
	
	// Apply filter, if active
	if(filterDict)
	{
		[self filterResults:YES usingValues:[filterDict objectForKey:@"values"]
		               forBundlingAttribute:[filterDict objectForKey:@"bundlingAttribute"]
					  newBundlingAttributes:[filterDict objectForKey:@"newBundlingAttributes"]];
	}
	
	[self enableUpdates];
	
	return userInfo;
}


/**
	Bundles a flat list of results into a hierarchical structure
	defined by the first item of bundlingAttributes
*/
- (NSMutableArray *)bundleResults:(NSArray *)theResults byAttributes:(NSArray *)attributes
{
	NSMutableDictionary *bundleDict = [NSMutableDictionary dictionary];
	
	NSMutableArray *bundledResults = [NSMutableArray array];
	
	NSString *bundlingAttribute = nil;
	if(attributes)
	{
		bundlingAttribute = [attributes objectAtIndex:0];
	}
	
	BOOL wrapping = NO;
	if([theResults count] > 0) wrapping = [[theResults objectAtIndex:0] isKindOfClass:[NSMetadataItem class]];

	NSEnumerator *resultsEnumerator = [theResults objectEnumerator];
	//NSMetadataItem *mdItem;
	id theItem;
	while(theItem = [resultsEnumerator nextObject])
	{	
		PAQueryBundle *bundle;
		
		if(bundlingAttribute)
		{
			NSString *bundleValue;
			
			if(wrapping)
			{
				// theItem is a NSMetadataItem
				
				// TODO: this can't work as there is not replacementValue category any more!
				
				id valueToBeReplaced = [theItem valueForAttribute:bundlingAttribute];
				bundleValue = [PATaggableObject replaceMetadataValue:valueToBeReplaced
														forAttribute:bundlingAttribute];
			} else {
				// theItem is a PAQueryItem
				bundleValue = [theItem valueForAttribute:bundlingAttribute];
			}
		
			bundle = [bundleDict objectForKey:bundleValue];
			if(!bundle)
			{
				bundle = [[PAQueryBundle alloc] init];
				[bundle setValue:bundleValue];
				[bundle setBundlingAttribute:bundlingAttribute];
				[bundleDict setObject:bundle forKey:bundleValue];
				[bundle release];
			}			
		}
		
		PAFile *item;
		if(wrapping)			
			item = [PAFile fileWithNSMetadataItem:(NSMetadataItem *)theItem];
		else
			item = theItem;
		
		if(bundlingAttribute)
		{
			[bundle addResultItem:item];
		} else {
			[bundledResults addObject:item];
		}
	}
	
	if(bundlingAttribute)
	{
		NSEnumerator *bundleEnumerator = [bundleDict objectEnumerator];
		PAQueryBundle *bundle;
		while(bundle = [bundleEnumerator nextObject])
		{
			// Bundle at next level if needed
			NSMutableArray *nextBundlingAttributes = [attributes mutableCopy];
			[nextBundlingAttributes removeObjectAtIndex:0];
			
			if([nextBundlingAttributes count] > 0)
			{
				NSArray *subResults = [self bundleResults:[bundle results]
											 byAttributes:nextBundlingAttributes];
				[bundle setResults:subResults];
			}
		
			[bundledResults addObject:bundle];
			
			[nextBundlingAttributes release];
		}
	}
	
	return bundledResults;
}

-   (void)filterResults:(BOOL)flag
			usingValues:(NSArray *)filterValues
   forBundlingAttribute:(NSString *)attribute
  newBundlingAttributes:(NSArray *)newAttributes
{	
	if(!flag) 
	{		
		[filterDict release];
		filterDict = nil;
		return;
	}
	
	// If there is already a filter applied, we may check if it's the right one
	BOOL isSameFilter = NO;
	/*if(filterDict)
	{
		isSameFilter = YES;
		if(![[filterDict objectForKey:@"values"] isEqualTo:filterValues]) isSameFilter = NO;
		if(![[filterDict objectForKey:@"bundlingAttribute"] isEqualTo:attribute]) isSameFilter = NO;
		if([filterDict objectForKey:@"newBundlingAttributes"] &&
		   ![[filterDict objectForKey:@"newBundlingAttributes"] isEqualTo:newAttributes]) isSameFilter = NO;
	}*/
	
	// Return if we already have results for this filter
	if(isSameFilter && flatFilteredResults) return;
	
	// Store current filter values for later use
	
	[filterDict release];
	if(attribute)
	{
		filterDict = [[NSMutableDictionary alloc] initWithCapacity:3];
		if(filterValues) [filterDict setObject:filterValues forKey:@"values"];
		if(attribute) [filterDict setObject:attribute forKey:@"bundlingAttribute"];
		if(newAttributes) [filterDict setObject:newAttributes forKey:@"newBundlingAttributes"];
	}

	[flatFilteredResults release];
	flatFilteredResults = nil;
	flatFilteredResults = [[NSMutableArray alloc] init];

	NSEnumerator *enumerator = [flatResults objectEnumerator];
	PAFile *item;
	while(item = [enumerator nextObject])
	{		
		id valueForAttribute = [item valueForAttribute:attribute];
		
		if([valueForAttribute isKindOfClass:[NSString class]])
		{
			if([filterValues containsObject:valueForAttribute])
			{
				[flatFilteredResults addObject:item];
			}
		} else {
			NSLog(@"couldn't properly filter results");
		}
	}
	
	[filteredResults release];
	filteredResults = nil;
	filteredResults = [[self bundleResults:flatFilteredResults byAttributes:newAttributes] retain];
}

- (BOOL)hasResultsUsingFilterWithValues:(NSArray *)filterValues
                   forBundlingAttribute:(NSArray *)attribute
{
	NSEnumerator *enumerator = [flatResults objectEnumerator];
	PAFile *item;
	while(item = [enumerator nextObject])
	{		
		id valueForAttribute = [item valueForAttribute:attribute];
		
		if([valueForAttribute isKindOfClass:[NSString class]])
		{
			if([filterValues containsObject:valueForAttribute])
			{
				return YES;
			}
		} else {
			NSLog(@"Error in hasResultsUsingFilterWithValues");
		}
	}
	
	return NO;
}

- (void)trashItems:(NSArray *)items errorWindow:(NSWindow *)window
{
	[self disableUpdates];
	
	NSString *trashDir = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
	
	NSEnumerator *e = [items objectEnumerator];
	PAFile *item;

	while (item = [e nextObject])
	{
		PAFile *file = [PAFile fileWithPath:[item valueForAttribute:(id)kMDItemPath]];
		
		// Move to trash
		[[NSFileManager defaultManager] trashFileAtPath:[file path]];
		
		// Remove tags from trashed file to give spotlight enough time
		// TODO leave this to PAFile!!
		PAFile *trashedFile = [PAFile fileWithPath:[trashDir stringByAppendingPathComponent:[file filename]]];
		[trashedFile removeAllTags];

		// Remove from flatresults
		for(int k = 0; k < [flatResults count]; k++)
		{
			if([[flatResults objectAtIndex:k] isEqualTo:item])
			{
				[flatResults removeObjectAtIndex:k];
				break;
			}
		}
	}
	
	[self setResults:[self bundleResults:flatResults byAttributes:bundlingAttributes]];	
	
	// Apply filter, if active
	if(filterDict)
	{
		[self filterResults:YES usingValues:[filterDict objectForKey:@"values"]
		               forBundlingAttribute:[filterDict objectForKey:@"bundlingAttribute"]
					  newBundlingAttributes:[filterDict objectForKey:@"newBundlingAttributes"]];
	}
	
	[self enableUpdates];
}

/*- (BOOL)renameItem:(PAQueryItem *)item to:(NSString *)newName errorWindow:(NSWindow *)window
{
	errorWindow = window;
	
	NSFileManager *fm = [NSFileManager defaultManager];

	PAFile		*file = [PAFile fileWithPath:[item valueForAttribute:(id)kMDItemPath]];
	NSString	*source = [file path];
	NSString	*destination = [file directory];
	
	// Ignore case-sensitive changes to the extension - TEMP for now
	newName = [newName substringToIndex:[newName length] - [[file extension] length]];
	destination = [destination stringByAppendingPathComponent:newName];
	destination = [destination stringByAppendingString:[file extension]];
	
	// Return NO if source equals destination
	if([source isEqualToString:destination]) return NO;
	
	BOOL fileWasMovedToTemp = NO;
	NSString *tempDestination = nil;
	NSArray *tagsOnFiles = nil;
	
	if([source compare:destination options:NSCaseInsensitiveSearch] == NSOrderedSame)
	{
		tempDestination = [file directory];
		tempDestination = [tempDestination stringByAppendingPathComponent:@"~"];
		tempDestination = [tempDestination stringByAppendingString:newName];
		
		tagsOnFiles = [[file tags] allObjects];
		
		if([fm fileExistsAtPath:tempDestination])
			[fm removeFileAtPath:tempDestination handler:nil];
			
		fileWasMovedToTemp = [fm movePath:source toPath:tempDestination handler:nil];
	}
	
	BOOL fileWasMoved;
	if(tempDestination && fileWasMovedToTemp)
	{	
		[fm removeFileAtPath:destination handler:nil];
		fileWasMoved = [fm movePath:tempDestination toPath:destination handler:self];
		
		if(fileWasMoved)
		{
			[fm removeFileAtPath:tempDestination handler:nil];
		}
	} else {
		fileWasMoved = [fm movePath:source toPath:destination handler:self];
	}
	
	if(fileWasMoved)
	{
		// Write tags on file
		// TODO this should be handled internally by PAFile
		PAFile *newFile = [PAFile fileWithPath:destination];
		[newFile addTags:tagsOnFiles];
	
		[item setValue:newName forAttribute:(id)kMDItemDisplayName];
		[item setValue:destination forAttribute:(id)kMDItemPath];
	
		for(int i = 0; i < [flatResults count]; i++)
		{
			if([[flatResults objectAtIndex:i] isEqualTo:item])
			{
				[flatResults replaceObjectAtIndex:i withObject:item];
				break;
			}
		}
	
		// Re-bundle results
		if(filterDict)
		{
			[self filterResults:YES usingValues:[[[filterDict objectForKey:@"values"] retain] autorelease]
		               forBundlingAttribute:[[[filterDict objectForKey:@"bundlingAttribute"] retain] autorelease]
					  newBundlingAttributes:[[[filterDict objectForKey:@"newBundlingAttributes"] retain] autorelease]];
		}
	
		return YES;
	}
	else
	{
		return NO;
	}
}*/

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
	
	[alert beginSheetModalForWindow:errorWindow
	                  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
					    contextInfo:nil];
	
	return NO;
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	// nothing yet
}

- (void)updateQueryFromTags
{
	NSString *queryString = [self queryStringForTags:[tags selectedTags]];
	
	if ([queryString isEqualToString:@""])
	{
		[self createQuery];
	}
	else
	{
		[self setPredicate:[NSPredicate predicateWithFormat:queryString]];
		
		if (![self isStarted])
		{
			[self startQuery];
		}
	}
}

- (NSString*)queryStringForTags:(NSArray*)someTags
{
	NSMutableString *queryString = [NSMutableString stringWithString:@""];
	
	NSEnumerator *e = [someTags objectEnumerator];
	PATag *tag;
	
	if (tag = [e nextObject]) 
	{
		NSString *anotherTagQuery = [NSString stringWithFormat:@"(%@)",[tag query]];
		[queryString appendString:anotherTagQuery];
	}
	
	while (tag = [e nextObject]) 
	{
		NSString *anotherTagQuery = [NSString stringWithFormat:@" && (%@)",[tag query]];
		[queryString appendString:anotherTagQuery];
	}
	
	return queryString;
}

- (NSString*)queryInSpotlightSyntaxForTags:(NSArray*)someTags
{
	NSMutableString *queryString = [NSMutableString stringWithString:@""];
	
	NSEnumerator *e = [someTags objectEnumerator];
	PATag *tag;
	
	if (tag = [e nextObject]) 
	{
		NSString *anotherTagQuery = [NSString stringWithFormat:@"(%@)",[tag queryInSpotlightSyntax]];
		[queryString appendString:anotherTagQuery];
	}
	
	while (tag = [e nextObject]) 
	{
		NSString *anotherTagQuery = [NSString stringWithFormat:@" && (%@)",[tag queryInSpotlightSyntax]];
		[queryString appendString:anotherTagQuery];
	}
	
	return queryString;
}

#pragma mark Notifications
/**
	Wrap, process and forward notifications of NSMetadataQuery
*/
- (void)metadataQueryNote:(NSNotification *)note
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	if([[note name] isEqualTo:NSMetadataQueryDidStartGatheringNotification])
	{
		[flatFilteredResults release];
		flatFilteredResults = nil;
		[filteredResults release];
		filteredResults = nil;
		[nc postNotificationName:PAQueryDidStartGatheringNotification object:self];
	}
	
	/*if([[note name] isEqualTo:NSMetadataQueryGatheringProgressNotification])
	{
		[self synchronizeResults];
		[nc postNotificationName:PAQueryGatheringProgressNotification object:self];
	}*/
		
	if([[note name] isEqualTo:NSMetadataQueryDidUpdateNotification])
	{
		NSDictionary *userInfo = [self synchronizeResults];
		[nc postNotificationName:PAQueryDidUpdateNotification object:self userInfo:userInfo];
	}
		
	if([[note name] isEqualTo:NSMetadataQueryDidFinishGatheringNotification])
	{
		NSDictionary *userInfo = [self synchronizeResults];
		[nc postNotificationName:PAQueryDidFinishGatheringNotification object:self userInfo:userInfo];
	}
}

#pragma mark Accessors
- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

- (NSDictionary *)simpleGrouping
{
	return simpleGrouping;
}

- (void)setSimpleGrouping:(NSDictionary *)aDictionary
{
	[simpleGrouping release];
	simpleGrouping = [aDictionary retain];
}

- (NSPredicate *)predicate
{
	return predicate;
}

- (void)setPredicate:(NSPredicate *)aPredicate
{
	[aPredicate retain];
	[predicate release];
	predicate = aPredicate;
	[mdquery setPredicate:aPredicate];
}

- (NSArray *)bundlingAttributes
{
	return bundlingAttributes;
}

- (void)setBundlingAttributes:(NSArray *)attributes
{
	if(bundlingAttributes) [bundlingAttributes release];
	bundlingAttributes = [attributes retain];
	
	// Post notification
	//[[NSNotificationCenter defaultCenter] postNotificationName:PAQueryGroupingAttributesDidChange
	//													object:self];
}

- (NSArray *)sortDescriptors
{
	return [mdquery sortDescriptors];
}


- (void)setSortDescriptors:(NSArray *)descriptors
{
	[mdquery setSortDescriptors:descriptors];
}

- (PASelectedTags*)tags
{
	return tags;
}

- (void)setTags:(PASelectedTags*)otherTags
{
	[otherTags retain];
	[tags release];
	tags = otherTags;
	
	[self updateQueryFromTags];
}

- (BOOL)isStarted
{
	return [mdquery isStarted];
}

- (BOOL)isGathering
{
	return [mdquery isGathering];
}

- (BOOL)isStopped
{
	return [mdquery isStopped];
}

- (unsigned)resultCount
{
	return filterDict ? [filteredResults count] : [results count];
}

- (id)resultAtIndex:(unsigned)idx
{
	return filterDict ? [filteredResults objectAtIndex:idx] : [results objectAtIndex:idx];
}

- (NSArray *)results
{
	return filterDict ? filteredResults : results;
}

- (void)setResults:(NSMutableArray*)newResults
{
	[results release];
	[newResults retain];
	results = newResults;
}

- (NSMutableArray *)flatResults
{
	return filterDict ? flatFilteredResults : flatResults;
}

- (void)setFlatResults:(NSMutableArray*)newFlatResults
{
	[flatResults release];
	[newFlatResults retain];
	flatResults = newFlatResults;
}

- (NSArray *)filteredResults
{
	return filteredResults;
}

- (void)setFilteredResults:(NSMutableArray *)newResults
{
	[filteredResults release];
	filteredResults = [newResults retain];
}

- (NSArray *)flatFilteredResults
{
	return flatFilteredResults;
}

- (void)setFlatFilteredResults:(NSMutableArray *)newResults
{
	[flatFilteredResults release];
	flatFilteredResults = [newResults retain];
}

- (BOOL)hasFilter
{
	return filterDict ? YES : NO;
}


@end