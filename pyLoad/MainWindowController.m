//
//  MainWindowController.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "MainWindowController.h"
#import "DownloadListCellView.h"
#import "QueueListCellView.h"
#import "PYLLogLine.h"
#import "ThrobberModalWindowController.h"
#import "DictionaryHUDController.h"

#define kDownloadListItemCellIdentifier	@"DownloadListItem"
#define kQueueItemCellIdentifier		@"QueueItem"

@implementation MainWindowController {
	LoginSheetController *loginSheetController;
	CaptchaWindowController *captchaWindowController;
	ThrobberModalWindowController *throbberWindowController;
	DictionaryHUDController *inspector;
	BOOL alreadyKnowAboutCaptcha;
	NSUInteger connectingToLocalInstance;
}

#pragma mark - Login Sheet Management

- (void) loginSheetCancelled:(LoginSheetController *)controller {
	[self.window orderOut:self];
	[self windowWillClose:nil];
}

- (void) loginSheetCompleted:(LoginSheetController *)controller {
	if (!throbberWindowController) {
		throbberWindowController = [[ThrobberModalWindowController alloc] initWithWindowNibName:@"ThrobberModalWindowController"];
	}
	
	[NSApp beginSheet:throbberWindowController.window
	   modalForWindow:self.window
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:self];
	
    [_server release];

    if ([[[[controller tabView] selectedTabViewItem] label] isEqualToString:@"Remote"]) {
        // Remote Setup
        _server = [[PYLServer alloc] initWithRemoteAddress:controller.addressField.stringValue
                                                port:controller.portField.integerValue];
        _server.delegate = self;
        [_server connectWithUsername:controller.usernameField.stringValue
                            password:controller.passwordField.stringValue];
		
		connectingToLocalInstance = 0;
		throbberWindowController.textLabel.stringValue = [NSString stringWithFormat:@"Connecting to %@…", controller.addressField.stringValue];
    }
    else {
        // Local Setup
        _server = [[PYLServer alloc] initWithLocalPath:controller.pathField.stringValue usingPython:controller.pythonField.stringValue];
        _server.delegate = self;
		connectingToLocalInstance = 1;
		throbberWindowController.textLabel.stringValue = @"Starting local instance…";
    }
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

	// Appearance
	[[_freeSpaceField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[[_transferCountField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	// Now lets login
	[self presentLoginSheet:self];
}

- (void)windowWillClose:(NSNotification *)notification {
	[_server disconnect];
}

- (void) dealloc {
	[throbberWindowController release];
	[captchaWindowController release];
	[loginSheetController release];
	[inspector release];
	[super dealloc];
}

#pragma mark - Server Polling

- (void) poll {
	[_server refreshDownloadList];
	[_server updateStatus];
	[_server refreshQueue];

//	// XXX: Should we be polling logs locally? This should probably only happen when the drawer is out, but that's more plumbing.
//	if ([_server isLocal]) {
//		[_server fetchLogs];
//	}
	
	if ([_server isConnected]) {
		[self performSelector:_cmd withObject:nil afterDelay:1.0f];
	}
}

#pragma mark - Window Actions

- (IBAction)setSpeedLimit:(id)sender {
	NSAlert *alert = [NSAlert alertWithMessageText:@"Set Speed Limit" defaultButton:@"OK" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Enter a speed (in kilobytes per second) to throttle the total transfer speed to."];
	[alert setIcon:[NSImage imageNamed:@"speedLimitSign"]];
	
	NSTextField *speedLimitField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)];
	[alert setAccessoryView:speedLimitField];
	
	[alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
		if (returnCode == NSModalResponseOK) {
			[_server setSpeedLimit:[speedLimitField integerValue]];
		}
		
		[speedLimitField release];
	}];
}

- (IBAction)addPackage:(id)sender {
	NewPackageWindowController *npc = [[NewPackageWindowController alloc] initWithWindowNibName:@"NewPackageWindowController"];
	npc.delegate = self;
	
	[NSApp beginSheet:npc.window
	   modalForWindow:self.window
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:self];
	
    [npc attemptPasteboardExtraction:sender];
    
	// Released in cancel or add
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

- (IBAction)restartSelected:(id)sender {
	id item = [_outlineView itemAtRow:[_outlineView selectedRow]];
	
	NSString *fid = item[@"fid"];
	if (fid) {
		[_server restartFileId:[fid integerValue]];
	}
}

- (IBAction)cancelSelected:(id)sender {
	id item = [_outlineView itemAtRow:[_outlineView selectedRow]];

	// TODO: Check if it's a package and cancel the package instead
	
	[_server cancelLinkId:[item[@"fid"] integerValue]];
}

- (IBAction)clearCompleted:(id)sender {
	[_server removeAllCompletePackages];
}

- (IBAction)toggleInspector:(id)sender {
	if (!inspector) {
		inspector = [[DictionaryHUDController alloc] initWithWindowNibName:@"DictionaryHUDController"];

		id item = [_outlineView itemAtRow:[_outlineView selectedRow]];
		if (item) {
			inspector.dictionary = item;
		}
	}
	
	if ([inspector.window isVisible]) {
		[inspector.window orderOut:sender];
	}
	else {
		[inspector showWindow:sender];
	}
}

- (IBAction)toggleThrottling:(id)sender {
	[_server setThrottling:_throttleMenuItem.state != NSOnState];
}

#pragma mark - NewPackageWindowDelegate Methods

- (void) newPackageControllerDidCancel:(NewPackageWindowController *)controller {
	[controller release];
}

- (void) newPackageControllerDidAddPackage:(NewPackageWindowController *)controller {
	[_server addPacakgeNamed:controller.nameField.stringValue withLinks:controller.linksView.string password:controller.passwordField.stringValue destination:(PYLDestination)(controller.destinationMatrix.selectedRow + 1)];
	[controller release];
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
	[throbberWindowController dismiss:self];
    self.window.title = [NSString stringWithFormat:@"pyLoad — %@", server.address];
    
	[server checkFreeSpace];
	[server fetchCoreConfig];
	[self poll];
}

- (void) serverDisconnected:(PYLServer *)server {
	if (connectingToLocalInstance) {
		connectingToLocalInstance++;
		[_server connectLocally];
	}
	else {
		[throbberWindowController dismiss:self];
		[self presentLoginSheet:self];
	}
}

- (void) server:(PYLServer *)server didRefreshDownloadList:(NSArray *)list {
	// TODO: Also capture state of what is collapsed and what isn't
	NSIndexSet *selectedRows = [_outlineView selectedRowIndexes];
	[_outlineView reloadData];
	[_outlineView selectRowIndexes:selectedRows byExtendingSelection:NO];
}

- (void) server:(PYLServer *)server didUpdateActiveCount:(NSUInteger)active queueCount:(NSUInteger)queueCount totalCount:(NSUInteger)totalCount {
    _transferCountField.stringValue = [NSString stringWithFormat:@"%lu Active | %lu Incomplete | %lu Total", active, queueCount, totalCount];
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
	// NOTE: This is only safe because we don't use the list passed in this class
	[self server:server didRefreshDownloadList:nil];
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
	[_logView scrollRangeToVisible:NSMakeRange(_logView.string.length, 0)];
}

- (void) server:(PYLServer *)server didChangeThrottledState:(BOOL)throttlingEnabled {
	[_throttleMenuItem setState:throttlingEnabled ? NSOnState : NSOffState];
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

#pragma mark NSOutlineView Delegate and Data Source Methods

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	return [self outlineView:outlineView isItemExpandable:item];
}

- (NSUInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if (item == nil) {
		return [_server.queue count];
	}
	
	if ([item isKindOfClass:[NSDictionary class]] && item[@"links"]) {
		return [item[@"links"] count];
	}
		
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	if ([item isKindOfClass:[NSDictionary class]] && item[@"links"]) {
		return YES;
	}
	
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {
	if (item == nil) {
		return [_server.queue[index] retain];
	}
	
	if ([item isKindOfClass:[NSDictionary class]] && item[@"links"]) {
		return item[@"links"][index];
	}
	
	return nil;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([item isKindOfClass:[NSDictionary class]] && item[@"links"]) {
		QueueListCellView *result = [outlineView makeViewWithIdentifier:kQueueItemCellIdentifier owner:self];
		result.server = _server;
		return [result reconfigureWithDictionary:item];
	}
	
	if ([item isKindOfClass:[NSDictionary class]] && item[@"statusmsg"]) {
		NSDictionary *downloadItem = [_server downloadItemForFid:[item[@"fid"] integerValue]];
		
        DownloadListCellView *result = [outlineView makeViewWithIdentifier:kDownloadListItemCellIdentifier owner:self];
        result.server = _server;

        if (downloadItem) {
			return [result reconfigureWithDictionary:downloadItem];
		}
        else {
            return [result reconfigureWithDictionary:item];
        }
		
	}
	
	return nil;

}

- (CGFloat)outlineView:(NSOutlineView *)outlineView
     heightOfRowByItem:(id)item {
    if ([item isKindOfClass:[NSDictionary class]] && item[@"links"]) {
        return 20.0f;
    }
    
    return 48.0f;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	inspector.dictionary = [_outlineView itemAtRow:[_outlineView selectedRow]];
}

@end
