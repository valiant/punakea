//
//  PAResultsMultiItemCell.h
//  punakea
//
//  Created by Daniel on 15.04.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAResultsMultiItemMatrix.h"


@interface PAResultsMultiItemCell : NSCell {

	NSArray						*items;
	PAResultsMultiItemMatrix	*matrix;

}

@end
