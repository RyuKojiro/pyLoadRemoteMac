//
//  DownloadListCellView.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "DownloadListCellView.h"

@implementation DownloadListCellView

+ (NSString *) statusLabelTextForDictionary:(NSDictionary *)dict {
	switch ([dict[@"status"] integerValue]) {
		case 0:
			return @"Finished";
		case 9:
		case 1:
			return @"Offline";
		case 2:
		case 3:
			return @"Queued";
		case 4:
			return @"Skipped";
		case 5: { // These brackets are required in clang for some reason
			NSString *waitTime = dict[@"format_wait"];
			return (waitTime ? [NSString stringWithFormat:@"Waiting… %@", waitTime] : @"Waiting…");
		}
		case 11:
		case 13:
			return @"Processing…";
		case 8:
			return @"Failed";
		
	}
	
	NSUInteger totalBytes = [dict[@"size"] integerValue];
	NSUInteger remaining = [dict[@"bleft"] integerValue];
	NSUInteger speed = [dict[@"speed"] integerValue];
	return [NSString stringWithFormat:@"Downloading… %@%% (%@ / %@) %@ remaining (%@/s)",
			dict[@"percent"],
			[NSByteCountFormatter stringFromByteCount:totalBytes - remaining countStyle:NSByteCountFormatterCountStyleFile],
			[NSByteCountFormatter stringFromByteCount:totalBytes countStyle:NSByteCountFormatterCountStyleFile],
			dict[@"format_eta"],
			[NSByteCountFormatter stringFromByteCount:speed countStyle:NSByteCountFormatterCountStyleFile]];
}

+ (NSString *)extensionForFile:(NSString *)file {
	// Some dumb uploaders do this
	if ([[file pathExtension] isEqualToString:@"html"]) {
		return [[file substringToIndex:[file length] - 5] pathExtension];
	}

	// Mega.co.nz does this
	if ([[file pathExtension] isEqualToString:@"crypted"]) {
		return [[file substringToIndex:[file length] - 8] pathExtension];
	}

	return [file pathExtension];
}

- (void) setActiveAppearance:(BOOL)active {
	// #1 = When active, #2 = Inactive

	[_statusLabel setHidden:!active];
	[_nameLabel setHidden:!active];
	[_statusLabel2 setHidden:active];
	[_nameLabel2 setHidden:active];

	[_progressBar setIndeterminate:!active];

	if (active) {
		[_progressBar startAnimation:self];
	}
	else {
		[_progressBar stopAnimation:self];
	}
}

- (instancetype) reconfigureWithDictionary:(NSDictionary *)dict {
	[self setActiveAppearance:NO];

    NSString *extension = [DownloadListCellView extensionForFile:dict[@"name"]];
	
	_nameLabel.stringValue = dict[@"name"];
	
	NSDictionary *labelDict = [_server downloadItemForFid:[dict[@"fid"] integerValue]];
	_statusLabel.stringValue = [DownloadListCellView statusLabelTextForDictionary:labelDict ? labelDict : dict];
	_icon.image = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
    
    NSString *packageName = dict[@"packageName"];
    _packageLabel.stringValue = packageName ? packageName : @"";
    
	_pluginLabel.stringValue = dict[@"plugin"];

    double progress = [dict[@"percent"] doubleValue];
    _progressBar.doubleValue = progress;

    NSString *statusMesage = dict[@"statusmsg"];
    if (progress == 0.0f && [statusMesage isEqualToString:@"finished"]) {
		[self setActiveAppearance:YES];
        _progressBar.doubleValue = 100.0f;
    }
    
	if ([dict[@"bleft"] integerValue] < [dict[@"size"] integerValue] && !([dict[@"bleft"] integerValue] == 0 && [dict[@"percent"] integerValue] == 0)) {
		[self setActiveAppearance:YES];
	}
	
	_entityId = [dict[@"fid"] integerValue];
	
	_nameLabel2.stringValue = _nameLabel.stringValue;
	_statusLabel2.stringValue = _statusLabel.stringValue;
	
	return self;
}

- (IBAction)cancel:(id)sender {
	[_server fetchLogs];
//	[_server cancelLinkId:_linkId];
}

@end
