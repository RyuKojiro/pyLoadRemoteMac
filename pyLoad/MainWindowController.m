//
//  MainWindowController.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "MainWindowController.h"
#import "DownloadListCellView.h"
#import "NewPackageWindowController.h"

#define kMainWindowCellIdentifier	@"DownloadListItem"

#define kLastServerAddressKey		@"lastServerAddress"
#define kLastServerPortKey			@"lastServerPort"

@implementation MainWindowController {
	LoginSheetController *loginSheetController;
	CaptchaWindowController *captchaWindowController;
	BOOL alreadyKnowAboutCaptcha;
}

#pragma mark - Login Sheet Management

- (void) loginSheetCancelled:(LoginSheetController *)controller {
	[self.window orderOut:self];
}

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

	// Appearance
	[[_freeSpaceField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[[_transferCountField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	// Now lets login
	[self presentLoginSheet:self];
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

- (IBAction)addPackage:(id)sender {
	NewPackageWindowController *npc = [[NewPackageWindowController alloc] initWithWindowNibName:@"NewPackageWindowController"];
	[NSApp beginSheet:npc.window
	   modalForWindow:self.window
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:self];
	//[npc release];
}

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

- (IBAction)stopAll:(id)sender {
	// This should also cancel all current downloads to make sure it is an actual immediate halt
	[_server pauseServer];
}

- (IBAction)resumeAll:(id)sender {
	[_server unpauseServer];
}

#pragma mark - CaptchaWindowDelegate Methods

- (void) captchaWindowController:(CaptchaWindowController *)controller didGetSolution:(NSString *)solution forId:(NSUInteger)captchaId{
	[_server submitCaptchaSolution:solution forCaptchaId:captchaId];
	alreadyKnowAboutCaptcha = NO;
}


#pragma mark - List Actions

- (IBAction)cancel:(id)sender {
	
}

#pragma mark - PYLServerDelegate Methods

- (void) server:(PYLServer *)server didUpdatePausedStatus:(BOOL)paused {
	_playPauseButton.image = paused ? [NSImage imageNamed:@"go"] : [NSImage imageNamed:@"stop"];
	_playPauseButton.label = paused ? @"Resume All" : @"Stop All";
	_playPauseButton.action = paused ? @selector(resumeAll:) : @selector(stopAll:);
}

- (void) serverConnected:(PYLServer *)server {
	[server checkFreeSpace];
	[self poll];
}

- (void) serverDisconnected:(PYLServer *)server {
	[self presentLoginSheet:self];
}

- (void) server:(PYLServer *)server didRefreshDownloadList:(NSArray *)list {
	NSIndexSet *selectedRows = [_tableView selectedRowIndexes];
	[_tableView reloadData];
	[_tableView selectRowIndexes:selectedRows byExtendingSelection:NO];
	
	// Refresh list count at bottom
	NSUInteger count = _server.downloadList.count;
	_transferCountField.stringValue = [NSString stringWithFormat:@"%lu Transfer%@", count, (count == 1) ? @"" : @"s" ];
}

- (void) serverHasCaptchaWaiting:(PYLServer *)server {
	if (!alreadyKnowAboutCaptcha) {
		alreadyKnowAboutCaptcha = YES;
		if ([NSApp keyWindow] == self.window) {
			[self presentCaptchaSolver:self];
		}
		else {
			NSUserNotification *notification = [[NSUserNotification alloc] init];
			notification.title = @"Captcha Available";
			notification.informativeText = @"Click this notification to solve the captcha. You have 10 seconds before the captcha check fails.";
			notification.hasActionButton = YES;
			notification.actionButtonTitle = @"Solve";
			
			[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
			[[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self]; // FIXME: We need to do something different for multi-server
			[notification release];
		}
	}
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
	_speedMenuItem.title = [NSString stringWithFormat:@"%@/s", bytes];
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
	if ([_server.downloadList[row][@"percent"] integerValue]) {
		[result.progressBar setIndeterminate:NO];
	}
	
	return result;
}

@end
