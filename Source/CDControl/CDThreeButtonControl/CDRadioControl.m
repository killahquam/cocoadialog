//
//  CDRadioControl.m
//  cocoaDialog
//
//  Created by Mark Whitaker on 9/23/11.
//  Copyright (c) 2011 Mark Whitaker. All rights reserved.
//

#import "CDRadioControl.h"

@implementation CDRadioControl

- (NSDictionary *) availableKeys
{
	NSNumber *vNone = [NSNumber numberWithInt:CDOptionsNoValues];
	NSNumber *vOne = [NSNumber numberWithInt:CDOptionsOneValue];
	NSNumber *vMul = [NSNumber numberWithInt:CDOptionsMultipleValues];

	return [NSDictionary dictionaryWithObjectsAndKeys:
            vNone,@"allow-mixed",
            vMul, @"items",
            vOne, @"selected",
            vMul, @"mixed",
            vMul, @"disabled",
            vOne, @"rows",
            vOne, @"columns",
            nil];
}

- (BOOL) validateOptions {
    // Check that we're in the right sub-class
    if (![self isMemberOfClass:[CDRadioControl class]]) {
        if ([options hasOpt:@"debug"]) {
			[self debug:@"This run-mode is not properly classed."];
		}
        return NO;
    }
	// Check that at least button1 has been specified
	if (![options optValue:@"button1"])	{
		if ([options hasOpt:@"debug"]) {
			[self debug:@"Must supply at least --button1"];
		}
		return NO;
	}
    // Check that at least one item has been specified
    NSArray *items = [NSArray arrayWithArray:[options optValues:@"items"]];
    if (![items count]) {
		if ([options hasOpt:@"debug"]) {
			[self debug:@"Must supply at least one --items"];
		}
		return NO;
	}
    // Load nib
	if (![NSBundle loadNibNamed:@"tbc" owner:self]) {
		if ([options hasOpt:@"debug"]) {
			[self debug:@"Could not load tbc.nib"];
		}
		return NO;
	}
    // Everything passed
    return YES;
}

- (BOOL)isReturnValueEmpty
{
    NSArray * items = [controlMatrix cells];
    if (items != nil && [items count]) {
        NSCell * selectedCell = [controlMatrix selectedCell];
        if (selectedCell != nil) {
            return NO;
        }
        else {
            return YES;
        }
    }
    else {
        return NO;
    }
}

- (NSString *) returnValueEmptyText
{
    NSArray * items = [controlMatrix cells];
    if ([items count] > 1) {
        return @"You must select at least one item before continuing.";
    }
    else {
        return [NSString stringWithFormat: @"You must select the item \"%@\" before continuing.", [[controlMatrix cellAtRow:0 column:0] title]];
    }
}

- (void) createControl {
    // Validate control before continuing
	if (![self validateControl:options]) {
        return;
    }

    NSString * labelText = @"";
    if ([options hasOpt:@"label"] && [options optValue:@"label"] != nil) {
        labelText = [options optValue:@"label"];
    }
	[self setTitleButtonsLabel:labelText];
}

- (void) controlHasFinished:(int)button {
    NSArray * radioArray = [controlMatrix cells];
    if (radioArray != nil && [radioArray count]) {
        NSCell * selectedCell = [controlMatrix selectedCell];
        if (selectedCell != nil) {
            if ([[self options] hasOpt:@"string-output"]) {
                [controlReturnValues addObject:[selectedCell title]];
            }
            else {
                [controlReturnValues addObject:[NSString stringWithFormat:@"%d", [[controlMatrix selectedCell] tag]]];
            }
        }
        else {
            [controlReturnValues addObject:[NSString stringWithFormat:@"%d", -1]];
        }
    }
    else {
        [controlReturnValues addObject:[NSString stringWithFormat:@"%d", -1]];
    }
    [super controlHasFinished:button];
}

- (void) setControl:(id)sender {
    // Setup the control:
    NSArray *items = [NSArray arrayWithArray:[options optValues:@"items"]];
    unsigned long selected = (unsigned long)-1L;
    NSArray *disabled = [[[NSArray alloc] init] autorelease];


    if ([options hasOpt:@"selected"]) {
        selected = (unsigned long)[[options optValue:@"selected"] intValue];
    }

    if ([options hasOpt:@"disabled"]) {
        disabled = [options optValues:@"disabled"];
    }

    // Set default precedence: columns, if both are present or neither are present:
    int matrixPrecedence = 0;

    // Set default number of columns:
    unsigned long columns = 1UL;
    // Set specified number of columns:
    if ([options hasOpt:@"columns"]) {
        columns = (unsigned long)[[options optValue:@"columns"] intValue];
        if (columns < 1UL) {
            columns = 1UL;
        }
    }

    // Set default number of rows:
    unsigned long rows = 1UL;
    // Set specified number of rows:
    if ([options hasOpt:@"rows"]) {
        rows = (unsigned long)[[options optValue:@"rows"] intValue];
        if (rows < 1UL) {
            rows = 1UL;
        }
        if (rows > [items count]){
            rows = [items count];
        }
        // User has specified number of rows, but not columns.
        // Set precedence to expand columns, not rows:
        if (![options hasOpt:@"columns"]) {
            matrixPrecedence = 1;
        }
    }

    [self setControl:self
          matrixRows:(NSInteger)rows
       matrixColumns:(NSInteger)columns
               items:items
          precedence:matrixPrecedence];
    rows = (unsigned long)[controlMatrix numberOfRows];
    columns = (unsigned long)[controlMatrix numberOfColumns];

    NSMutableArray *controls = [[[NSMutableArray alloc] init] autorelease];

    // Create the control for each item:
    unsigned long currItem = 0UL;
    NSEnumerator *en = [items objectEnumerator];
    float cellWidth = 0.0f;
    id obj;
    while ((obj = [en nextObject])) {
        NSButton *button = [[[NSButton alloc] init] autorelease];
        [button setButtonType:NSRadioButton];
        [button setTitle:[items objectAtIndex:currItem]];
        if ((disabled != nil) && [disabled count]) {
            if ([disabled containsObject:[NSString stringWithFormat:@"%i", currItem]]) {
                [[button cell] setEnabled: NO];
            }
        }
        [[button cell] setTag:(NSInteger)currItem];
        [button sizeToFit];
        if ([button frame].size.width > cellWidth) {
            cellWidth = (float)[button frame].size.width;
        }
        [controls addObject:[button cell]];
        currItem++;
    }

    // Set other attributes of matrix:
    [controlMatrix setAutosizesCells:NO];
    [controlMatrix setCellSize:NSMakeSize(cellWidth, 18.0f)];
    [controlMatrix setAllowsEmptySelection:YES];
    [controlMatrix deselectAllCells];
    [controlMatrix setMode:NSRadioModeMatrix];

    // Populate the matrix:
    currItem = 0;
    for (unsigned long currColumn = 0UL; currColumn <= (columns - 1UL); currColumn++) {
        for (unsigned long currRow = 0UL; currRow <= (rows - 1UL); currRow++) {
            if (currItem <= [items count] - 1) {
                NSButtonCell *cell = [controls objectAtIndex:currItem];
                [controlMatrix putCell:cell
                                 atRow:(NSInteger)currRow
                                column:(NSInteger)currColumn];
                if (selected == currItem) {
                    [controlMatrix selectCellAtRow:(NSInteger)currRow
                                            column:(NSInteger)currColumn];
                }
                currItem++;
            }
            else {
                NSCell *blankCell = [[[NSCell alloc] init] autorelease];
                [blankCell setType:NSNullCellType];
                [blankCell setEnabled:NO];
                [controlMatrix putCell:blankCell
                                 atRow:(NSInteger)currRow
                                column:(NSInteger)currColumn];
            }
        }
    }

    if (obj != NULL) {
        return;
    }
    /* else return by falling off the end; it is the same either way */
}

@end

/* EOF */
