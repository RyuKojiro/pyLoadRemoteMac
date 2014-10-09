//
//  CaptchaWindowController.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/9/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "CaptchaWindowController.h"

@interface CaptchaWindowController ()

@end

@implementation CaptchaWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)solve:(id)sender {
	[self.window orderOut:self];
	[NSApp endSheet:self.window];
	
	[_delegate captchaWindowController:self didGetSolution:self.solutionTextField.stringValue];
}

@end
