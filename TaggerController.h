/* TaggerController */

#import <Cocoa/Cocoa.h>
#import "PATags.h"
#import "PATagger.h"
#import "PARelatedTags.h"
#import "PATypeAheadFind.h"

@interface TaggerController : NSWindowController
{	
	IBOutlet NSTokenField *tagField; /**< shows tags which are on all selected files */
	IBOutlet NSTextField *restTagField; /**< shows tags which are on some selected files */
	
	IBOutlet NSArrayController *fileController;
	IBOutlet NSArrayController *popularTagsController;
	
	PASelectedTags *currentCompleteTagsInField; /**< holds the relevant tags of tagField (as a copy) */

	PATags *tags; /**< reference to all tags (same as in controller) */
	
	NSArray *popularTagsSortDescriptors;
	
	PATypeAheadFind *typeAheadFind;
	
	PARelatedTags *relatedTags;
}

- (id)initWithWindowNibName:(NSString*)windowNibName tags:(PATags*)newTags;

/**
adds new files to the fileController
 @param newFiles files to add
 */
- (void)addFiles:(NSMutableArray*)newFiles;

- (PASelectedTags*)currentCompleteTagsInField;
- (void)setCurrentCompleteTagsInField:(PASelectedTags*)newTags;

@end
