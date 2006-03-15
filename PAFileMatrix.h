//
//  PAFileMatrix.h
//  punakea
//
//  Created by Daniel on 08.03.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PAFileMatrixHeaderCell.h"
#import "PAFileMatrixItemCell.h"

@interface PAFileMatrix : NSMatrix {
	NSMetadataQuery *query;
	NSMutableDictionary *dictItemKind;
	NSMutableDictionary *dictItemPath;
}

@end