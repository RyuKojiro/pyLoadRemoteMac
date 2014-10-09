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

@property (assign) IBOutlet MainWindowController *window;
@end

@implementation AppDelegate

- (void)dealloc {
	[_window release];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	_window = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
	[_window showWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end
