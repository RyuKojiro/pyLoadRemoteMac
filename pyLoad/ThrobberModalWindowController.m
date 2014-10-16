//
//  ThrobberModalWindowController.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/15/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "ThrobberModalWindowController.h"

@interface ThrobberModalWindowController ()

@property (assign) IBOutlet NSProgressIndicator *throbber;

@end

@implementation ThrobberModalWindowController

- (void) awakeFromNib {
	[_throbber startAnimation:self];
}
   
- (IBAction)dismiss:(id)sender {
	if ([self.window isSheet] && [self.window isVisible]) {
		[self.window orderOut:self];
		[NSApp endSheet:self.window];
	}
}

@end
