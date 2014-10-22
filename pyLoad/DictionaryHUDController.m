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
	NSDictionary *_userFriendlyKeys;
	NSMutableArray *_filteredKeys;
}

@dynamic dictionary;

- (void) dealloc {
	[_filteredKeys release];
	[_dictionary release];
	[_userFriendlyKeys release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification {
	[_delegate dictionaryHUDWillClose:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"UserFriendlyKeyNames"
													 ofType:@"plist"];
	_userFriendlyKeys = [[NSDictionary alloc] initWithContentsOfFile:path];
	
	_filteredKeys = [[NSMutableArray alloc] init];
}

- (NSDictionary *) dictionary {
	return _dictionary;
}

- (void) setDictionary:(NSDictionary *)dictionary {
	[_dictionary release];
	
	[_filteredKeys removeAllObjects];
	
	for (NSString *key in [dictionary allKeys]) {
		if (_userFriendlyKeys[key]) {
			[_filteredKeys addObject:key];
		}
	}
	
	[_tableView reloadData];
	_dictionary = [dictionary retain];
}

#pragma mark - NSTableViewDataSource and Delegate Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return _dictionary ? [_filteredKeys count] : 1;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	
	if (_dictionary) {
		if ([[[aTableColumn headerCell] title] isEqualToString:@"Key"]) {
			return _userFriendlyKeys[_filteredKeys[rowIndex]];
		}
		else {
			return _dictionary[_filteredKeys[rowIndex]];
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
