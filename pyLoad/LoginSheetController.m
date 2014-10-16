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

@interface LoginSheetController ()

@end

@implementation LoginSheetController

- (IBAction)cancel:(id)sender {
	[[NSUserDefaults standardUserDefaults] setObject:_addressField.stringValue forKey:kLastServerAddressKey];
	[[NSUserDefaults standardUserDefaults] setObject:_portField.stringValue forKey:kLastServerPortKey];
	[[NSUserDefaults standardUserDefaults] setObject:_pathField.stringValue forKey:kLastLocalPathKey];

	[_delegate loginSheetCancelled:self];
	[NSApp endSheet:self.window];
	[self.window orderOut:sender];
}

- (IBAction)done:(id)sender {
	[[NSUserDefaults standardUserDefaults] setObject:_addressField.stringValue forKey:kLastServerAddressKey];
	[[NSUserDefaults standardUserDefaults] setObject:_portField.stringValue forKey:kLastServerPortKey];
	[[NSUserDefaults standardUserDefaults] setObject:_pathField.stringValue forKey:kLastLocalPathKey];

	[_delegate loginSheetCompleted:self];
	[NSApp endSheet:self.window];
	[self.window orderOut:sender];
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
}

@end
