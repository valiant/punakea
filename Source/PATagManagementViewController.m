//
//  PATagManagementViewController.m
//  punakea
//
//  Created by Johannes Hoffart on 13.07.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PATagManagementViewController.h"


@implementation PATagManagementViewController

- (id)initWithNibName:(NSString*)nibName
{
	if (self = [super init])
	{
		tagger = [PATagger sharedInstance];
		tags = [tagger tags];
		query = [[PAQuery alloc] init];
		
		[self setDeleting:NO];
		[self setRenaming:NO];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
		sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor,nil];
		[sortDescriptor release];
		
		[NSBundle loadNibNamed:nibName owner:self];
	}
	return self;
}

- (void)dealloc
{
	[sortDescriptors release];
	[query release];
	[super dealloc];
}

#pragma mark accessors
- (BOOL)isDeleting
{
	return deleting;
}

- (void)setDeleting:(BOOL)flag
{
	deleting = flag;
}

- (BOOL)isRenaming
{
	return renaming;
}

- (void)setRenaming:(BOOL)flag
{
	renaming = flag;
}

#pragma mark actions
- (void)removeTagsFromFiles:(NSArray*)tags
{
	[self setDeleting:YES];
	
	NSEnumerator *tagEnumerator = [tags objectEnumerator];
	PATag *tag;
	
	while (tag = [tagEnumerator nextObject])
	{
		[tagger removeTag:tag];
	}
	
	[self setDeleting:NO];
}

- (void)renameTag:(PATag*)oldTag toTag:(PATag*)newTag
{
	if ([[oldTag name] isEqualToString:[newTag name]])
	{
		return;
	}
	
	[self setRenaming:YES];
	
	NSArray *files = [query filesForTag:oldTag];
	[tagger renameTag:[oldTag name] toTag:[newTag name] onFiles:files];
	
	[self setRenaming:NO];
}

@end