//
//  MainWindowController.h
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LoginSheetController.h"
#import "PYLServer.h"
#import "CaptchaWindowController.h"

@interface MainWindowController : NSWindowController <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, LoginSheetDelegate, PYLServerDelegate, NSUserNotificationCenterDelegate, CaptchaWindowDelegate, NSDrawerDelegate>

@property (retain) PYLServer *server;
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSTextField *freeSpaceField;
@property (assign) IBOutlet NSMenuItem *speedMenuItem;
@property (assign) IBOutlet NSToolbarItem *playPauseButton;
@property (assign) IBOutlet NSTextField *transferCountField;
@property (assign) IBOutlet NSTextView *logView;

- (IBAction)presentLoginSheet:(id)sender;
- (IBAction)serverSettings:(id)sender;

@end
