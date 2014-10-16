//
//  ThrobberModalWindowController.h
//  pyLoad
//
//  Created by Daniel Loffgren on 10/15/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ThrobberModalWindowController : NSWindowController

@property (assign) IBOutlet NSTextField *textLabel;

- (IBAction)dismiss:(id)sender;

@end
