//
//  LoginSheetController.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "LoginSheetController.h"

@interface LoginSheetController ()

@end

@implementation LoginSheetController

- (IBAction)cancel:(id)sender {
	[_delegate loginSheetCancelled:self];
	[NSApp endSheet:self.window];
	[self.window orderOut:sender];
}

- (IBAction)done:(id)sender {
	[_delegate loginSheetCompleted:self];
	[NSApp endSheet:self.window];
	[self.window orderOut:sender];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
