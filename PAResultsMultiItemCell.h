//
//  PAResultsMultiItemCell.h
//  punakea
//
//  Created by Daniel on 15.04.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAResultsMultiItem.h"
#import "PAResultsMultiItemMatrix.h"


@interface PAResultsMultiItemCell : NSTextFieldCell {

	PAResultsMultiItem *item;
	PAResultsMultiItemMatrix *matrix;

}

- (PAResultsMultiItem *)item;
- (void)setItem:(PAResultsMultiItem *)anItem;

@end
