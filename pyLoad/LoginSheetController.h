//
//  LoginSheetController.h
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LoginSheetController;

@protocol LoginSheetDelegate <NSObject>

- (void) loginSheetCompleted:(LoginSheetController *)controller;

@end

@interface LoginSheetController : NSWindowController

@property (assign) IBOutlet NSTextField *addressField;
@property (assign) IBOutlet NSTextField *portField;
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSSecureTextField *passwordField;

@property (assign) id <LoginSheetDelegate> delegate;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
