//
//  DictionaryHUDController.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/21/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "DictionaryHUDController.h"

@interface DictionaryHUDController ()

@property (assign) IBOutlet NSTableView *tableView;

@end

@implementation DictionaryHUDController {
	NSDictionary *_dictionary;
}

@dynamic dictionary;

- (void) dealloc {
	[_dictionary release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification {
	[_delegate dictionaryHUDWillClose:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSDictionary *) dictionary {
	return _dictionary;
}

- (void) setDictionary:(NSDictionary *)dictionary {
	[_dictionary release];
	[_tableView reloadData];
	_dictionary = [dictionary retain];
}

#pragma mark - NSTableViewDataSource and Delegate Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return _dictionary ? [_dictionary count] : 1;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if (_dictionary) {
		if ([[[aTableColumn headerCell] title] isEqualToString:@"Key"]) {
			return [_dictionary allKeys][rowIndex];
		}
		else {
			return _dictionary[[_dictionary allKeys][rowIndex]];
		}
	}
	else {
		if ([[[aTableColumn headerCell] title] isEqualToString:@"Key"]) {
			return @"Nothing Selected";
		}
		else {
			return @"";
		}
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	return NO;
}

@end
