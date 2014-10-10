//
//  CaptchaWindowController.h
//  pyLoad
//
//  Created by Daniel Loffgren on 10/9/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PYLServer.h"

@class CaptchaWindowController;

@protocol CaptchaWindowDelegate <NSObject>

- (void) captchaWindowController:(CaptchaWindowController *)controller didGetSolution:(NSString *)solution forId:(NSUInteger)captchaId;

@end

@interface CaptchaWindowController : NSWindowController

@property (assign) IBOutlet NSImageView *captchaImageView;
@property (assign) IBOutlet NSTextField *solutionTextField;
@property (assign) IBOutlet NSButton *solveButton;
@property (assign) id <CaptchaWindowDelegate> delegate;
@property (readwrite) NSUInteger captchaId;
@property (assign) IBOutlet NSProgressIndicator *throbber;

- (IBAction)solve:(id)sender;
- (IBAction)cancel:(id)sender;

@end
