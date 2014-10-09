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

#pragma mark - Request Convenience Methods

+ (NSString *) lastPathComponentForRequestType:(PYLRequestType)type {
	switch (type) {
		case PYLRequestTypeLogin:
			return @"login";
		case PYLRequestTypeCheckForCaptcha:
			return @"isCaptchaWaiting";
		case PYLRequestTypeFetchDownloadsList:
			return @"statusDownloads";
		default:
			return nil;
	}
}

+ (PYLRequestType) requestTypeForLastPathComponent:(NSString *)lastPathComponent {
	if ([lastPathComponent isEqualToString:@"login"]) {
		return PYLRequestTypeLogin;
	}
	if ([lastPathComponent isEqualToString:@"isCaptchaWaiting"]) {
		return PYLRequestTypeCheckForCaptcha;
	}
	if ([lastPathComponent isEqualToString:@"statusDownloads"]) {
		return PYLRequestTypeFetchDownloadsList;
	}
	return PYLRequestTypeNone;
}

+ (PYLRequestType) requestTypeForRequest:(NSURLRequest *)req {
	return [PYLServer requestTypeForLastPathComponent:[[req URL] lastPathComponent]];
}

- (NSMutableURLRequest *) mutableRequestForRequestType:(PYLRequestType)type {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self urlWithLastPathComponent:[PYLServer lastPathComponentForRequestType:type]]];
	[request setHTTPMethod:@"POST"];

	return [request autorelease];
}

#pragma mark - Requests

- (void) connectWithUsername:(NSString *)username password:(NSString *)password {
	self.username = username;
	
	// POST urlencoded data
	NSMutableURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeLogin];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
 
	NSMutableData *postBody = [[NSMutableData alloc] init];
	[postBody appendData:[[NSString stringWithFormat:@"password=%@&username=%@",
						   [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
						   [username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	[postBody release];
	
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	[data release];
	data = [[NSMutableData alloc] init];
	
	[connection start];
}

- (void) disconnect {
	cookie = nil;
	_connected = NO;
	_username = nil;
}

- (void) refreshDownloadList {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeFetchDownloadsList];
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	[data release];
	data = [[NSMutableData alloc] init];
	
	[connection start];
}

- (void) checkForCaptcha {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeCheckForCaptcha];
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	[data release];
	data = [[NSMutableData alloc] init];
	
	[connection start];
}

#pragma mark - NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
		//NSLog(@"Response: %@", connection);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
	[data appendData:d];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	switch ([PYLServer requestTypeForRequest:[connection originalRequest]]) {
		case PYLRequestTypeLogin: {
			NSLog(@"%@", connection);
			_connected = YES;
			[_delegate serverConnected:self];
		} break;
		case PYLRequestTypeFetchDownloadsList: {
			NSError *e = nil;
			[_downloadList release];
			_downloadList = [[NSJSONSerialization JSONObjectWithData:data options:0 error:&e] retain];
			[_delegate server:self didRefreshDownloadList:_downloadList];
		} break;
		case PYLRequestTypeCheckForCaptcha: {
			if ([data length] == 4) { // "true"
				[_delegate serverHasCaptchaWaiting:self];
			}
		} break;
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"Connection %@ failed with error %@.", connection, error);
}

@end
