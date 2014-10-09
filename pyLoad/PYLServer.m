//
//  PYLServer.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "PYLServer.h"

@implementation PYLServer {
	NSString *cookie;
	NSMutableData *data;
}

- (void)dealloc {
	[data release];
	[super dealloc];
}

- (NSURL *) urlWithLastPathComponent:(NSString *)endpoint {
	NSString *string = [NSString stringWithFormat:@"http://%@:%lu/api/%@", self.address, (unsigned long)self.port, endpoint];
	return [NSURL URLWithString:string];
}

- (instancetype) initWithAddress:(NSString *)address port:(NSUInteger)port {
	if ((self = [self init])) {
		self.address = address;
		self.port = port;
	}
	return self;
}

- (void) connectWithUsername:(NSString *)username password:(NSString *)password {
	if(_state != PYLServerStateIdle) return;	// TODO: queue it up
	self.username = username;
	
	// POST urlencoded data
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self urlWithLastPathComponent:@"login"]];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
 
	NSMutableData *postBody = [[NSMutableData alloc] init];
	[postBody appendData:[[NSString stringWithFormat:@"password=%@&username=%@",
						   [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
						   [username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	[postBody release];
	
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[request release];
	
	[data release];
	data = [[NSMutableData alloc] init];
	_state = PYLServerStateLoggingIn;
	
	[connection start];
}

- (void) disconnect {
	cookie = nil;
	_connected = NO;
	_username = nil;
}

- (void) refreshDownloadList {
	if(_state != PYLServerStateIdle) return;	// TODO: queue it up
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self urlWithLastPathComponent:@"statusDownloads"]];
	[request setHTTPMethod:@"POST"];
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[request release];
	
	[data release];
	data = [[NSMutableData alloc] init];
	_state = PYLServerStateFetchingDownloadsList;
	
	[connection start];
}

#pragma mark - NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	switch (_state) {
		case PYLServerStateLoggingIn: {
			NSLog(@"%@", connection);
		} break;
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
	[data appendData:d];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	switch (_state) {
		case PYLServerStateLoggingIn: {
			NSLog(@"%@", connection);
		} break;
	}
	
	_state = PYLServerStateIdle;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	_state = PYLServerStateError;
	NSLog(@"Connection %@ failed with error %@.", connection, error);
}

@end
