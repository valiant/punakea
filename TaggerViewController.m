#import "TaggerViewController.h"

@implementation TaggerViewController

- (void)awakeFromNib {
	ti = [[PATagger alloc] init];
}

- (IBAction)setTagsForFile:(id)sender {
	NSArray* tagNames = [[tagList stringValue] componentsSeparatedByString:@","];
	
	NSEnumerator *e = [tagNames objectEnumerator];
	NSString *tagName;
	NSMutableArray *tags = [[NSMutableArray alloc] init];
	
	while (tagName = [e nextObject]) {
		PATag *tag = [[PATag alloc] initWithName:tagName];
		[tags addObject:tag];
		[tag release];
	}		
	
	NSLog(@"trying to write %@ to %@",tags,[filePath stringValue]);
	[ti addTagsToFile:tags filePath:[filePath stringValue]];
}

@end
