//
//  PYLServer.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "PYLServer.h"

@implementation PYLServer

- (instancetype) initWithAddress:(NSString *)address port:(NSUInteger)port {
	if ((self = [self init])) {
		self.address = address;
		self.port = port;
	}
	return self;
}

- (void) connectWithUsername:(NSString *)username password:(NSString *)password {
	self.username = username;
}

- (void) disconnect {
	
}

@end
