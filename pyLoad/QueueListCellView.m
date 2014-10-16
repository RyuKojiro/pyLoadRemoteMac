//
//  QueueListCellView.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/10/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "QueueListCellView.h"

@implementation QueueListCellView

- (instancetype) reconfigureWithDictionary:(NSDictionary *)dict {
	self.nameLabel.stringValue = dict[@"name"];
	self.icon.image = [NSImage imageNamed:NSImageNameFolder];

	NSUInteger bytesComplete = [dict[@"sizedone"] integerValue];
	NSUInteger bytesTotal = [dict[@"sizetotal"] integerValue];
	
	if (bytesTotal) {
		self.statusLabel.stringValue = [NSString stringWithFormat:@"%lu%% – %@/%@ items complete – %@/%@",
										(100 * bytesComplete/bytesTotal),
										dict[@"linksdone"],
										dict[@"linkstotal"],
										[NSByteCountFormatter stringFromByteCount:bytesComplete countStyle:NSByteCountFormatterCountStyleFile],
										[NSByteCountFormatter stringFromByteCount:bytesTotal countStyle:NSByteCountFormatterCountStyleFile]];
	}
	else {
		self.statusLabel.stringValue = @"Offline";
	}
	
	self.packageLabel.stringValue = @"";
	self.pluginLabel.stringValue = @"Package";
	
	self.entityId = [dict[@"pid"] integerValue];
	
	return self;
}

- (IBAction)cancel:(id)sender {
	[self.server removePackageId:self.entityId];
	[self.server refreshQueue];
}

@end
