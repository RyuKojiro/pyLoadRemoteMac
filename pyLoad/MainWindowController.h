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

@interface MainWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, LoginSheetDelegate, PYLServerDelegate, NSUserNotificationCenterDelegate>

@property (retain) PYLServer *server;
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSTextField *freeSpaceField;
@property (assign) IBOutlet NSTextField *speedField;

- (IBAction)presentLoginSheet:(id)sender;
- (IBAction)serverSettings:(id)sender;

@end
