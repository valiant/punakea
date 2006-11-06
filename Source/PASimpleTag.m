//
//  PASimpleTag.m
//  punakea
//
//  Created by Johannes Hoffart on 15.02.06.
//  Copyright 2006 nudge:nudge. All rights reserved.
//

#import "PASimpleTag.h"
@interface PASimpleTag (PrivateAPI)

- (BOOL)isEqualToTag:(PASimpleTag*)otherTag;

@end

@implementation PASimpleTag

#pragma mark init
- (id)initWithCoder:(NSCoder*)coder 
{
	// overwritten to keep coder from overwriting query
	self = [super init];
	if (self) 
	{
		[self setName:[coder decodeObjectForKey:@"name"]];
		lastClicked = [[coder decodeObjectForKey:@"lastClicked"] retain];
		lastUsed = [[coder decodeObjectForKey:@"lastUsed"] retain];
		[coder decodeValueOfObjCType:@encode(unsigned long)	at:&clickCount];
		[coder decodeValueOfObjCType:@encode(unsigned long)	at:&useCount];
	}
	return self;
}

#pragma mark functionality
// overwriting super-class methods
- (void)setName:(NSString*)aName 
{
	[super setName:aName];

	[self setQuery:[NSString stringWithFormat:@"kMDItemFinderComment LIKE '*@%@*'",aName]];
}

- (NSString*)queryInSpotlightSyntax
{
	return [NSString stringWithFormat:@"kMDItemFinderComment == \"*@%@*\"cd",[self name]];
}

// implementing needed super-class methods
- (float)absoluteRating
{
	return log10(clickCount + useCount);
}

- (float)relativeRatingToTag:(PATag*)otherTag
{	
	return [self absoluteRating] / [otherTag absoluteRating];
}

#pragma mark euality testing
- (BOOL)isEqual:(id)other 
{
	if (!other || ![self isKindOfClass:[other class]]) 
        return NO;
    if (other == self)
        return YES;
	
    return [self isEqualToTag:other];
}

- (BOOL)isEqualToTag:(PASimpleTag*)otherTag 
{
	if ([[self name] caseInsensitiveCompare:[otherTag name]] == NSOrderedSame)
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

- (unsigned)hash 
{
	return [name hash] ^ [query hash];
}

#pragma mark copying
- (id)copyWithZone:(NSZone *)zone
{
	PASimpleTag *newTag = [[[PASimpleTag alloc] init] autorelease];
	[newTag setName:[self name]];
	[newTag setUseCount:[self useCount]];
	[newTag setValue:[self lastUsed] forKey:@"lastUsed"];
	[newTag setClickCount:[self clickCount]];
	[newTag setValue:[self lastClicked]  forKey:@"lastClicked"];
	return newTag;
}

@end