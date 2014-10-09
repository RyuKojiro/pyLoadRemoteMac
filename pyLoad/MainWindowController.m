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

#pragma mark - Login Sheet Management

- (void) loginSheetCompleted:(LoginSheetController *)controller {
	[_server release];
	_server = [[PYLServer alloc] initWithAddress:controller.addressField.stringValue
											port:controller.portField.integerValue];
	_server.delegate = self;
	[_server connectWithUsername:controller.usernameField.stringValue
						password:controller.passwordField.stringValue];
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

#pragma mark - Window Lifecycle

- (void)windowDidLoad {
    [super windowDidLoad];
	
	[self presentLoginSheet:self];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void) dealloc {
	[loginSheetController release];
	[super dealloc];
}

#pragma mark - Server Polling

- (void) poll {
	[_server refreshDownloadList];
	[_server checkForCaptcha];
	
	if ([_server isConnected]) {
		[self performSelector:_cmd withObject:nil afterDelay:1.0f];
	}
}

#pragma mark - List Menu Actions

- (IBAction)cancel:(id)sender {
	
}

#pragma mark - PYLServerDelegate Methods

- (void) serverConnected:(PYLServer *)server {
	[server checkFreeSpace];
	[self poll];
}

- (void) server:(PYLServer *)server didRefreshDownloadList:(NSArray *)list {
	NSIndexSet *selectedRows = [_tableView selectedRowIndexes];
	[_tableView reloadData];
	[_tableView selectRowIndexes:selectedRows byExtendingSelection:NO];
}

- (void) serverHasCaptchaWaiting:(PYLServer *)server {
	NSUserNotification *notification = [[NSUserNotification alloc] init];
	notification.title = @"Captcha Available";
	notification.informativeText = @"Click this notification to solve the captcha. You have 10 seconds before the captcha check fails.";
	notification.hasActionButton = YES;
	notification.actionButtonTitle = @"Solve";
	
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
	[notification release];
}

- (void) server:(PYLServer *)server didUpdateFreeSpace:(NSUInteger)bytesFree {
	NSString *bytes = [NSByteCountFormatter stringFromByteCount:bytesFree countStyle:NSByteCountFormatterCountStyleFile];
	_freeSpaceField.stringValue = [NSString stringWithFormat:@"%@ free", bytes];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [[_server downloadList] count];
}

#pragma mark - NSTableViewDelegate Methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	DownloadListCellView *result = [tableView makeViewWithIdentifier:kMainWindowCellIdentifier owner:self];
	
	NSString *extension = [DownloadListCellView extensionForFile:_server.downloadList[row][@"name"]];
	
	result.nameLabel.stringValue = _server.downloadList[row][@"name"];
	result.statusLabel.stringValue = [DownloadListCellView statusLabelTextForDictionary:_server.downloadList[row]];
	result.icon.image = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
	result.packageLabel.stringValue = _server.downloadList[row][@"packageName"];
	result.pluginLabel.stringValue = _server.downloadList[row][@"plugin"];
	result.progressBar.doubleValue = [_server.downloadList[row][@"percent"] doubleValue];
	// TODO: A more reliable test here
	if (result.progressBar.doubleValue) {
		[result.progressBar setIndeterminate:NO];
	}
	
	return result;
}

@end
