//
//  NewPackageWindowController.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/9/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "NewPackageWindowController.h"

@interface NewPackageWindowController ()

@end

@implementation NewPackageWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)attemptPasteboardExtraction:(id)sender {
    NSMutableArray *links = [[NSMutableArray alloc] init];
    
    NSArray *results = [[NSPasteboard generalPasteboard] readObjectsForClasses:@[[NSAttributedString class]]
                                                                       options:0];
    
    for (NSAttributedString *result in results) {
        [result enumerateAttribute:NSLinkAttributeName
                           inRange:NSMakeRange(0, [result length])
                           options:0
                        usingBlock:^(id value, NSRange range, BOOL *stop) {
                            if (value) {
                                [links addObject:value];
                            }
                        }];
    }
    
    if ([links count]) {
        _linksView.string = @"";
        
        NSMutableString *newString = [[NSMutableString alloc] init];
        for (NSURL *link in links) {
            [newString appendString:[link absoluteString]];
            [newString appendString:@"\n"];
        }
        _linksView.string = newString;
        [newString release];
    }
    
    [links release];
}

- (IBAction)create:(id)sender {
	[self.window orderOut:self];
	[NSApp endSheet:self.window];
    [_delegate newPackageControllerDidAddPackage:self];
}

- (IBAction)cancel:(id)sender {
	[self.window orderOut:self];
	[NSApp endSheet:self.window];
    if ([_delegate respondsToSelector:@selector(newPackageControllerDidCancel:)]) {
        [_delegate newPackageControllerDidCancel:self];
    }
}


@end
