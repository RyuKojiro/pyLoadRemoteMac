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

#define kLastServerAddressKey		@"lastServerAddress"
#define kLastServerPortKey			@"lastServerPort"

@implementation MainWindowController {
	LoginSheetController *loginSheetController;
	CaptchaWindowController *captchaWindowController;
}

#pragma mark - Login Sheet Management

- (void) loginSheetCompleted:(LoginSheetController *)controller {
	[_server release];
	_server = [[PYLServer alloc] initWithAddress:controller.addressField.stringValue
											port:controller.portField.integerValue];
	_server.delegate = self;
	[_server connectWithUsername:controller.usernameField.stringValue
						password:controller.passwordField.stringValue];
	
	[[NSUserDefaults standardUserDefaults] setObject:controller.addressField.stringValue forKey:kLastServerAddressKey];
	[[NSUserDefaults standardUserDefaults] setObject:controller.portField.stringValue forKey:kLastServerPortKey];
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
	
	NSString *lastAddress = [[NSUserDefaults standardUserDefaults] stringForKey:kLastServerAddressKey];
	if (lastAddress) {
		loginSheetController.addressField.stringValue = lastAddress;
	}
	
	NSString *lastPort = [[NSUserDefaults standardUserDefaults] stringForKey:kLastServerPortKey];
	
	if (lastPort) {
		loginSheetController.portField.stringValue = lastPort;
	}
}

#pragma mark - Window Lifecycle

- (void)windowDidLoad {
    [super windowDidLoad];
	
	[self presentLoginSheet:self];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void) dealloc {
	[captchaWindowController release];
	[loginSheetController release];
	[super dealloc];
}

#pragma mark - Server Polling

- (void) poll {
	[_server refreshDownloadList];
	[_server updateStatus];
	[_server refreshQueue];
	
	if ([_server isConnected]) {
		[self performSelector:_cmd withObject:nil afterDelay:1.0f];
	}
}

#pragma mark - Window Actions

- (IBAction)serverSettings:(id)sender {
	
}

- (IBAction)restartFailed:(id)sender {
	[_server restartFailed];
}

- (IBAction)presentCaptchaSolver:(id)sender {
	if (!captchaWindowController) {
		captchaWindowController = [[CaptchaWindowController alloc] initWithWindowNibName:@"CaptchaWindowController"];
		captchaWindowController.delegate = self;
	}
	
	// Recycle the window
	captchaWindowController.captchaImageView.image = nil;
	captchaWindowController.solutionTextField.stringValue = @"";
	[captchaWindowController.throbber setHidden:NO];
	[captchaWindowController.throbber startAnimation:self];
	
	// Populate it on demand
	[_server fetchCaptchaWithCompletionHandler:^(NSUInteger captchaId, NSImage *image) {
		captchaWindowController.captchaImageView.image = image;
		captchaWindowController.captchaId = captchaId;
		[captchaWindowController.solveButton setEnabled:YES];
		[captchaWindowController.throbber setHidden:YES];
	}];
	
	[NSApp beginSheet:captchaWindowController.window
	   modalForWindow:self.window
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:self];
}

#pragma mark - CaptchaWindowDelegate Methods

- (void) captchaWindowController:(CaptchaWindowController *)controller didGetSolution:(NSString *)solution forId:(NSUInteger)captchaId{
	[_server submitCaptchaSolution:solution forCaptchaId:captchaId];
}


#pragma mark - List Actions

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
	[[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self]; // FIXME: We need to do something different for multi-server
	[notification release];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
	[self presentCaptchaSolver:self];
}

- (void) server:(PYLServer *)server didUpdateFreeSpace:(NSUInteger)bytesFree {
	NSString *bytes = [NSByteCountFormatter stringFromByteCount:bytesFree countStyle:NSByteCountFormatterCountStyleFile];
	_freeSpaceField.stringValue = [NSString stringWithFormat:@"%@ free", bytes];
}

- (void) server:(PYLServer *)server didRefreshQueue:(NSArray *)queue {
	
}

- (void) server:(PYLServer *)server didUpdateSpeed:(CGFloat)bytesPerSec {
	NSString *bytes = [NSByteCountFormatter stringFromByteCount:bytesPerSec countStyle:NSByteCountFormatterCountStyleFile];
	_speedField.stringValue = [NSString stringWithFormat:@"%@/s", bytes];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return _server.downloadList.count;
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
