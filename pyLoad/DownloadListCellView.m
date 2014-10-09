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
	return [NSString stringWithFormat:@"Downloading… %@ (%@ / %@) @ %@/s",
			dict[@"format_eta"],
			[NSByteCountFormatter stringFromByteCount:totalBytes - remaining countStyle:NSByteCountFormatterCountStyleFile],
			[NSByteCountFormatter stringFromByteCount:totalBytes countStyle:NSByteCountFormatterCountStyleFile],
			[NSByteCountFormatter stringFromByteCount:speed countStyle:NSByteCountFormatterCountStyleFile]];
}

+ (NSString *)extensionForFile:(NSString *)file {
	if ([[file pathExtension] isEqualToString:@"html"]) {
		return [[file substringToIndex:[file length] - 5] pathExtension];
	}
	
	return [file pathExtension];
}

@end
