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
#import "QueueListCellView.h"
#import "PYLLogLine.h"

#define kDownloadListItemCellIdentifier	@"DownloadListItem"
#define kQueueItemCellIdentifier		@"QueueItem"

#define kLastServerAddressKey			@"lastServerAddress"
#define kLastServerPortKey				@"lastServerPort"
#define kLastLocalPathKey               @"lastLocalPath"

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

    if ([[[[controller tabView] selectedTabViewItem] label] isEqualToString:@"Remote"]) {
        // Remote Setup
        _server = [[PYLServer alloc] initWithRemoteAddress:controller.addressField.stringValue
                                                port:controller.portField.integerValue];
        _server.delegate = self;
        [_server connectWithUsername:controller.usernameField.stringValue
                            password:controller.passwordField.stringValue];
    }
    else {
        // Local Setup
        _server = [[PYLServer alloc] initWithLocalPath:controller.pathField.stringValue];
        _server.delegate = self;
    }
	
	[[NSUserDefaults standardUserDefaults] setObject:controller.addressField.stringValue forKey:kLastServerAddressKey];
    [[NSUserDefaults standardUserDefaults] setObject:controller.portField.stringValue forKey:kLastServerPortKey];
    [[NSUserDefaults standardUserDefaults] setObject:controller.pathField.stringValue forKey:kLastLocalPathKey];
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

    NSString *lastPath = [[NSUserDefaults standardUserDefaults] stringForKey:kLastLocalPathKey];
    if (lastPath) {
        loginSheetController.pathField.stringValue = lastPath;
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
	[_server pauseServer];
	[_server cancelAllLinks];
}

- (IBAction)resumeAll:(id)sender {
	[_server unpauseServer];
}

- (IBAction)cancel:(id)sender {
	NSUInteger row = [_tableView selectedRow];

	if (row < _server.downloadList.count) {
		// FIXME: this couples the UI and server instances in a very nasty way
		[_server cancelLinkId:[_server.downloadList[row][@"fid"] integerValue]];
	}
	else {
		NSLog(@"Tried to cancel a package from the window");
	}
}

#pragma mark - CaptchaWindowDelegate Methods

- (void) captchaWindowController:(CaptchaWindowController *)controller didGetSolution:(NSString *)solution forId:(NSUInteger)captchaId{
	[_server submitCaptchaSolution:solution forCaptchaId:captchaId];
	alreadyKnowAboutCaptcha = NO;
}

#pragma mark - PYLServerDelegate Methods

- (void) server:(PYLServer *)server didUpdatePausedStatus:(BOOL)paused {
	_playPauseButton.image = paused ? [NSImage imageNamed:@"go"] : [NSImage imageNamed:@"stop"];
	_playPauseButton.label = paused ? @"Resume All" : @"Stop All";
	_playPauseButton.action = paused ? @selector(resumeAll:) : @selector(stopAll:);
}

- (void) serverConnected:(PYLServer *)server {
    self.window.title = [NSString stringWithFormat:@"pyLoad — %@", server.address];
    
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
	if ([NSApp keyWindow] == self.window) {
		[self presentCaptchaSolver:self];
	}
	else if (!alreadyKnowAboutCaptcha) {
		alreadyKnowAboutCaptcha = YES;
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

- (void) server:(PYLServer *)server didRefreshLogs:(NSArray *)logData {
	NSMutableString *logText = [[NSMutableString alloc] init];

	for (PYLLogLine *line in logData) {
		[logText appendFormat:@"%@ %@\n", line.importance, line.text];
	}
	
	[_logView setString:logText];
	[logText release];
}

#pragma mark - NSDrawerDelegate Methods

- (void)drawerWillOpen:(NSNotification *)notification {
	[_server fetchLogs];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return _server.downloadList.count + _server.queue.count;
}

#pragma mark - NSTableViewDelegate Methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (row < _server.downloadList.count) {
		DownloadListCellView *result = [tableView makeViewWithIdentifier:kDownloadListItemCellIdentifier owner:self];
		result.server = _server;
		return [result reconfigureWithDictionary:_server.downloadList[row]];
	}
	if (row >= _server.downloadList.count && row < (_server.downloadList.count + _server.queue.count)) {
		QueueListCellView *result = [tableView makeViewWithIdentifier:kQueueItemCellIdentifier owner:self];
		result.server = _server;
		return [result reconfigureWithDictionary:_server.queue[row - _server.downloadList.count]];
	}
	return nil;
}

@end
