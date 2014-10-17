//
//  NewPackageWindowController.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/9/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "NewPackageWindowController.h"

@interface NewPackageWindowController ()

@end

@implementation NewPackageWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)create:(id)sender {
	[self.window orderOut:self];
	[NSApp endSheet:self.window];
    [_delegate newPackageControllerDidAddPackage:self];
}

- (IBAction)cancel:(id)sender {
	[self.window orderOut:self];
	[NSApp endSheet:self.window];
    if ([_delegate respondsToSelector:@selector(newPackageControllerDidCancel:)]) {
        [_delegate newPackageControllerDidCancel:self];
    }
}


@end
