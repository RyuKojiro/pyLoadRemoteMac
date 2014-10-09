//
//  MainWindowController.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "MainWindowController.h"
#import "DownloadListCellView.h"

#define kMainWindowCellIdentifier	@"DownloadListItem"

@implementation MainWindowController {
	LoginSheetController *loginSheetController;
}

- (void) loginSheetCompleted:(LoginSheetController *)controller {
	[_server release];
	_server = [[PYLServer alloc] initWithAddress:controller.addressField.stringValue
											port:controller.portField.integerValue];
	_server.delegate = self;
	[_server connectWithUsername:controller.usernameField.stringValue
						password:controller.passwordField.stringValue];
}

- (void) dealloc {
	[loginSheetController release];
	[super dealloc];
}

- (IBAction)presentLoginSheet:(id)sender {
	if (!loginSheetController) {
		loginSheetController = [[LoginSheetController alloc] initWithWindowNibName:@"LoginSheetController"];
		loginSheetController.delegate = self;
	}
	
	[NSApp beginSheet:loginSheetController.window
	   modalForWindow:self.window
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
	
	[self presentLoginSheet:self];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)bam:(id)sender {
	[_server refreshDownloadList];
}

#pragma mark - PYLServerDelegate Methods

- (void) server:(PYLServer *)server didRefreshDownloadList:(NSArray *)list {
	[_tableView reloadData];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [[_server downloadList] count];
}

#pragma mark - NSTableViewDelegate Methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	DownloadListCellView *result = [tableView makeViewWithIdentifier:kMainWindowCellIdentifier owner:self];
	
	NSString *extension = [PYLServer extensionForString:_server.downloadList[row][@"name"]];
	
	result.nameLabel.stringValue = _server.downloadList[row][@"name"];
	result.statusLabel.stringValue = _server.downloadList[row][@"statusmsg"];
	result.icon.image = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
	result.packageLabel.stringValue = _server.downloadList[row][@"packageName"];
	result.pluginLabel.stringValue = _server.downloadList[row][@"plugin"];

	return result;
}

@end
