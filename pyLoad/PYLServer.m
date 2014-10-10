//
//  PYLServer.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "PYLServer.h"

#define PYLServerAssertConnection			if (!data) { \
												[_delegate serverDisconnected:self]; \
												return; \
											}


@implementation PYLServer {
	NSString *cookie;
}

- (NSURL *) urlWithLastPathComponent:(NSString *)endpoint {
	NSString *string = [NSString stringWithFormat:@"http://%@:%lu%@", self.address, (unsigned long)self.port, endpoint];
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
			return @"/api/login";
		case PYLRequestTypeCheckForCaptcha:
			return @"/api/isCaptchaWaiting";
		case PYLRequestTypeFetchDownloadsList:
			return @"/api/statusDownloads";
		case PYLRequestTypeCheckFreeSpace:
			return @"/api/freeSpace";
		case PYLRequestTypeFetchQueue:
			return @"/api/getQueue";
		case PYLRequestTypeRestartFailed:
			return @"/api/restartFailed";
		case PYLRequestTypeUpdateStatus:
			return @"/json/status";
		case PYLRequestTypeSubmitCaptcha:
		case PYLRequestTypeFetchCaptcha:
			return @"/json/set_captcha";
		case PYLRequestTypeUnpauseServer:
			return @"/api/unpauseServer";
		case PYLRequestTypePauseServer:
			return @"/api/pauseServer";
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
		PYLServerAssertConnection;
		
		// TODO: verify that the data is actually a pyload server
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
		PYLServerAssertConnection;
		
		NSError *e = nil;
		[_downloadList release];
		_downloadList = [[NSJSONSerialization JSONObjectWithData:data options:0 error:&e] retain];
		[_delegate server:self didRefreshDownloadList:_downloadList];
	}];
}

- (void) refreshQueue {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeFetchQueue];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;

		NSError *e = nil;
		[_queue release];
		_queue = [[NSJSONSerialization JSONObjectWithData:data options:0 error:&e] retain];
		[_delegate server:self didRefreshQueue:_queue];
	}];
}

- (void) checkForCaptcha {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeCheckForCaptcha];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;

		if ([data length] == 4) { // "true"
			[_delegate serverHasCaptchaWaiting:self];
		}
	}];
}

- (void) checkFreeSpace {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeCheckFreeSpace];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;

		NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		[_delegate server:self didUpdateFreeSpace:[str integerValue]];
		[str release];
	}];
}

- (void) updateStatus {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeUpdateStatus];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;

		NSError *e = nil;
		NSDictionary *status = [NSJSONSerialization JSONObjectWithData:data options:0 error:&e];
		
		[_delegate server:self didUpdateSpeed:[status[@"speed"] floatValue]];
		
		if ([status[@"captcha"] boolValue]) {
			[_delegate serverHasCaptchaWaiting:self];
		}
		
		[_delegate server:self didUpdatePausedStatus:[status[@"pause"] boolValue]];
	}];
}

- (void) restartFailed {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeRestartFailed];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;
	}];
}

- (void) fetchCaptchaWithCompletionHandler:(void (^)(NSUInteger captchaId, NSImage *image))handler {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeFetchCaptcha];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;

		NSError *e = nil;
		NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&e];
		
		NSImage *result = nil;
		NSUInteger captchaId = 0;
		if ([dictionary[@"captcha"] boolValue]) {
			captchaId = [dictionary[@"id"] integerValue];
			
			NSString *imgsrc = dictionary[@"src"];
			NSArray *parts = [imgsrc componentsSeparatedByString:@","];
			NSData *imageData = [[NSData alloc] initWithBase64EncodedString:parts[1] options:0];
			result = [[[NSImage alloc] initWithData:imageData] autorelease];
			[imageData release];
		}
		handler(captchaId, result);
	}];
}

- (void) submitCaptchaSolution:(NSString *)solution forCaptchaId:(NSUInteger)captchaId {
	NSMutableURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeSubmitCaptcha];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
 
	NSMutableData *postBody = [[NSMutableData alloc] init];
	[postBody appendData:[[NSString stringWithFormat:@"cap_id=%lu&cap_result=%@", captchaId, solution] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	[postBody release];
	
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;

		NSError *e = nil;
		NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&e];

		if ([dictionary[@"captcha"] boolValue]) { // "true"
			[_delegate serverHasCaptchaWaiting:self];
		}

	}];
}

- (void) pauseServer {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypePauseServer];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;

		NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if ([str isEqualToString:@"true"]) {
			[_delegate server:self didUpdatePausedStatus:YES];
		}
		[str release];
	}];
}

- (void) unpauseServer {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeUnpauseServer];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;

		NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if ([str isEqualToString:@"true"]) {
			[_delegate server:self didUpdatePausedStatus:NO];
		}
		[str release];
	}];
}

- (void) cancelLinkId:(NSUInteger)linkId {
	// NOTE: This one is a GET for some reason
	NSString *endpoint = [NSString stringWithFormat:@"/json/abort_link/%lu", linkId];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self urlWithLastPathComponent:endpoint]];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;
		
		// TODO: Look for {"response": "success"}
	}];
	[request release];
}

@end
