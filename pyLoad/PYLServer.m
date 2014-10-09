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
		case PYLRequestTypeCheckFreeSpace:
			return @"freeSpace";
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
	if ([lastPathComponent isEqualToString:@"freeSpace"]) {
		return PYLRequestTypeCheckFreeSpace;
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
	
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		_connected = YES;
		[_delegate serverConnected:self];
	}];
}

- (void) disconnect {
	cookie = nil;
	_connected = NO;
	_username = nil;
}

- (void) refreshDownloadList {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeFetchDownloadsList];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		NSError *e = nil;
		[_downloadList release];
		_downloadList = [[NSJSONSerialization JSONObjectWithData:data options:0 error:&e] retain];
		[_delegate server:self didRefreshDownloadList:_downloadList];
	}];
}

- (void) checkForCaptcha {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeCheckForCaptcha];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		if ([data length] == 4) { // "true"
			[_delegate serverHasCaptchaWaiting:self];
		}
	}];
}

- (void) checkFreeSpace {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeCheckFreeSpace];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		[_delegate server:self didUpdateFreeSpace:[str integerValue]];
		[str release];
	}];
}

@end
