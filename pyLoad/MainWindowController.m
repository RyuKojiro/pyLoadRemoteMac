//
//  MainWindowController.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "MainWindowController.h"

@implementation MainWindowController {
	LoginSheetController *loginSheetController;
}

- (void) loginSheetCompleted:(LoginSheetController *)controller {
	[_server release];
	_server = [[PYLServer alloc] initWithAddress:controller.addressField.stringValue
											port:controller.portField.integerValue];
	[_server connectWithUsername:controller.usernameField.stringValue
						password:controller.passwordField.stringValue];
}

- (void) dealloc {
	[LoginSheetController release];
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

#pragma mark - NSTableViewDataSource Methods

#pragma mark - NSTableViewDelegate Methods



@end
