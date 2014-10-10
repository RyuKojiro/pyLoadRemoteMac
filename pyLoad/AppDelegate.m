//
//  AppDelegate.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self newDocument:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (IBAction)newDocument:(id)sender {
	MainWindowController *window = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
	[window showWindow:self];
	// TODO: For now this leaks
}

@end
