//
//  LoginSheetController.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "LoginSheetController.h"

#define kLastServerAddressKey			@"lastServerAddress"
#define kLastServerPortKey				@"lastServerPort"
#define kLastLocalPathKey               @"lastLocalPath"
#define kLastPythonPathKey              @"lastPythonPath"

@interface LoginSheetController ()

@end

@implementation LoginSheetController

- (void) _persistFields {
	[[NSUserDefaults standardUserDefaults] setObject:_addressField.stringValue forKey:kLastServerAddressKey];
	[[NSUserDefaults standardUserDefaults] setObject:_portField.stringValue forKey:kLastServerPortKey];
	[[NSUserDefaults standardUserDefaults] setObject:_pathField.stringValue forKey:kLastLocalPathKey];
	[[NSUserDefaults standardUserDefaults] setObject:_pythonField.stringValue forKey:kLastPythonPathKey];
}

- (IBAction)cancel:(id)sender {
	[self _persistFields];
	[NSApp endSheet:self.window];
	[self.window orderOut:sender];

	[_delegate loginSheetCancelled:self];
}

- (IBAction)done:(id)sender {
	[self _persistFields];
	[NSApp endSheet:self.window];
	[self.window orderOut:sender];

	[_delegate loginSheetCompleted:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
	NSString *lastAddress = [[NSUserDefaults standardUserDefaults] stringForKey:kLastServerAddressKey];
	if (lastAddress) {
		_addressField.stringValue = lastAddress;
	}
	
	NSString *lastPort = [[NSUserDefaults standardUserDefaults] stringForKey:kLastServerPortKey];
	if (lastPort) {
		_portField.stringValue = lastPort;
	}
	
	NSString *lastPath = [[NSUserDefaults standardUserDefaults] stringForKey:kLastLocalPathKey];
	if (lastPath) {
		_pathField.stringValue = lastPath;
	}
	
	NSString *lastPython = [[NSUserDefaults standardUserDefaults] stringForKey:kLastPythonPathKey];
	if (lastPython) {
		_pythonField.stringValue = lastPython;
	}
}

@end
