//
//  NewPackageWindowController.h
//  pyLoad
//
//  Created by Daniel Loffgren on 10/9/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NewPackageWindowController;

@protocol NewPackageWindowDelegate <NSObject>
- (void) newPackageControllerDidAddPackage:(NewPackageWindowController *)controller;

@optional
- (void) newPackageControllerDidCancel:(NewPackageWindowController *)controller;

@end

@interface NewPackageWindowController : NSWindowController

@property (assign) IBOutlet NSTextField *nameField;
@property (assign) IBOutlet NSTextView *linksView;
@property (assign) IBOutlet NSTextField *passwordField;
@property (assign) IBOutlet NSMatrix *destinationMatrix;

@property (assign) id <NewPackageWindowDelegate> delegate;

@end
