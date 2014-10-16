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
		case 5:
			return [NSString stringWithFormat:@"Waiting… %@", dict[@"format_wait"]];
		case 11:
		case 13:
			return @"Processing…";
		
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

- (instancetype) reconfigureWithDictionary:(NSDictionary *)dict {
	NSString *extension = [DownloadListCellView extensionForFile:dict[@"name"]];
	
	_nameLabel.stringValue = dict[@"name"];
	_statusLabel.stringValue = [DownloadListCellView statusLabelTextForDictionary:dict];
	_icon.image = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
	_packageLabel.stringValue = dict[@"packageName"];
	_pluginLabel.stringValue = dict[@"plugin"];
	_progressBar.doubleValue = [dict[@"percent"] doubleValue];

	if ([dict[@"bleft"] integerValue] < [dict[@"size"] integerValue] && !([dict[@"bleft"] integerValue] == 0 && [dict[@"percent"] integerValue] == 0)) {
		[_progressBar setIndeterminate:NO];
	}
	
	_entityId = [dict[@"fid"] integerValue];
	
	return self;
}

- (IBAction)cancel:(id)sender {
	[_server fetchLogs];
//	[_server cancelLinkId:_linkId];
}

@end
