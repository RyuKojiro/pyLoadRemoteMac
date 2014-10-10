//
//  DownloadListCellView.h
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PYLServer.h"

@interface DownloadListCellView : NSTableCellView

@property (assign) IBOutlet NSTextField *nameLabel;
@property (assign) IBOutlet NSImageView *icon;
@property (assign) IBOutlet NSProgressIndicator *progressBar;
@property (assign) IBOutlet NSTextField *statusLabel;
@property (assign) IBOutlet NSTextField *pluginLabel;
@property (assign) IBOutlet NSTextField *packageLabel;

@property (assign) PYLServer *server;
@property (readwrite) NSUInteger linkId;

+ (NSString *) statusLabelTextForDictionary:(NSDictionary *)dict;
+ (NSString *) extensionForFile:(NSString *)file;

- (instancetype) reconfigureWithDictionary:(NSDictionary *)dict;

- (IBAction)cancel:(id)sender;

@end
