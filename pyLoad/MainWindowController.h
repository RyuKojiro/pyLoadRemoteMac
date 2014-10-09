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

@interface MainWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, LoginSheetDelegate, PYLServerDelegate>

@property (retain) PYLServer *server;
@property (assign) IBOutlet NSTableView *tableView;

- (IBAction)presentLoginSheet:(id)sender;

@end