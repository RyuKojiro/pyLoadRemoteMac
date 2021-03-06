//
//  PYLServer.m
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import "PYLServer.h"
#import "PYLLogLine.h"

#define PYLServerAssertConnection			if (!data) { \
												_connected = NO;\
												[_delegate serverDisconnected:self]; \
												return; \
											}

#define kPYLDefaultLocalHost        @"localhost"
#define kPYLDefaultLocalPort        8001
#define kPYLDefaultLocalUser        @"local"
#define kPYLDefaultLocalPassword    @"localSecret"

@implementation PYLServer {
	NSString *cookie;
    NSTask *localInstance;
}

- (NSURL *) urlWithLastPathComponent:(NSString *)endpoint {
	NSString *string = [NSString stringWithFormat:@"http://%@:%lu%@", self.address, (unsigned long)self.port, endpoint];
	return [NSURL URLWithString:string];
}

- (instancetype) initWithRemoteAddress:(NSString *)address port:(NSUInteger)port {
	if ((self = [self init])) {
		self.address = address;
		self.port = port;
        _local = NO;
	}
	return self;
}

- (instancetype) initWithLocalPath:(NSString *)pathToPyloadBinaries usingPython:(NSString *)pathToPython {
    if ((self = [self init])) {
        _local = YES;

        // Move pyload.conf aside if it exists
        if ([[NSFileManager defaultManager] fileExistsAtPath:[@"~/.pyload/pyload.conf" stringByExpandingTildeInPath]]) {
            //
        }

        // TODO: Put in canned config
        
        // start server and hold onto the task
        NSString *corePath = [[pathToPyloadBinaries stringByAppendingPathComponent:@"pyLoadCore.py"] stringByExpandingTildeInPath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:corePath]) {
            localInstance = [[NSTask launchedTaskWithLaunchPath:[pathToPython stringByExpandingTildeInPath] arguments:@[corePath]] retain];
        }
        else {
            NSLog(@"Looks like the instance you pointed to is damaged. It's missing pyLoadCore.py!");
            [_delegate serverDisconnected:self];
        }
        
        self.address = kPYLDefaultLocalHost;
        self.port = kPYLDefaultLocalPort;
		
		[self connectLocally];
    }
    return self;
}

- (void) dealloc {
	[self disconnect];
	[super dealloc];
}

- (void) connectLocally {
    [self connectWithUsername:kPYLDefaultLocalUser password:kPYLDefaultLocalPassword];
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
			return @"/api/getQueueData";
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
		case PYLRequestTypeCancelAll:
			return @"/api/stopAllDownloads";
		case PYLRequestTypeFetchLogs:
			return @"/logs/";
        case PYLRequestTypeAddPackage:
            return @"/json/add_package";
		case PYLRequestTypeSetGeneralConfigKeyValuePair:
			return @"/json/save_config/general";
		case PYLRequestTypeFetchCoreConfig:
			return @"/api/getConfig";
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
	[request setTimeoutInterval:3.0f];
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
	[localInstance terminate];
	[localInstance release];
	localInstance = nil;
	
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
        
        [_delegate server:self didUpdateActiveCount:[status[@"active"] integerValue] queueCount:[status[@"queue"] integerValue] totalCount:[status[@"total"] integerValue]];
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

- (void) cancelAllLinks {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeCancelAll];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;
	}];
}

- (void) removePackageId:(NSUInteger)packageId {
	// NOTE: This one is a GET for some reason
	NSString *endpoint = [NSString stringWithFormat:@"/api/deletePackages/[%lu]", packageId];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self urlWithLastPathComponent:endpoint]];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;
		
		// TODO: Look for "true"
	}];
	[request release];
}

- (void) removeAllCompletePackages {
	NSArray *q2 = [_queue copy];
	
	for (NSDictionary *item in q2) {
		NSUInteger linksTotal;
		NSString *ltString = item[@"linkstotal"];
		
		if ([ltString isKindOfClass:[NSNull class]]) {
			linksTotal = [item[@"links"] count];
		}
		else {
			linksTotal = [ltString integerValue];
		}
		
		if ([item[@"linksdone"] integerValue] == linksTotal) {
			[self removePackageId:[item[@"pid"] integerValue]];
		}
	}
    
    [q2 release];
}

- (void) fetchLogs {
	NSURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeFetchLogs];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;
		
		NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		[_delegate server:self didRefreshLogs:[PYLServer logLinesFromLogHTML:html]];
		[html release];
	}];
}

- (void) addPacakgeNamed:(NSString *)packageName withLinks:(NSString *)newlineSeparatedLinks password:(NSString *)password destination:(PYLDestination)destination {
    NSString *boundary = @"----WebKitFormBoundaryMUgIwkK6ft9mNHFM";
    
    NSMutableURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeAddPackage];
    [request addValue:[@"multipart/form-data; boundary=" stringByAppendingString:boundary]
   forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *postBody = [[NSMutableData alloc] init];

	NSData *newlineData = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
	
    [postBody appendData:[[NSString stringWithFormat:@"--%@\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[PYLServer formDataHeaderNamed:@"add_name"]];
	[postBody appendData:newlineData];
    [postBody appendData:[packageName dataUsingEncoding:NSUTF8StringEncoding]];
	
    [postBody appendData:[[NSString stringWithFormat:@"\n--%@\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[PYLServer formDataHeaderNamed:@"add_links"]];
	[postBody appendData:newlineData];
    [postBody appendData:[newlineSeparatedLinks dataUsingEncoding:NSUTF8StringEncoding]];

	[postBody appendData:[[NSString stringWithFormat:@"\n--%@\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[PYLServer formDataHeaderNamed:@"add_password"]];
	[postBody appendData:newlineData];
    if (password) [postBody appendData:[password dataUsingEncoding:NSUTF8StringEncoding]];
    
	[postBody appendData:[[NSString stringWithFormat:@"\n--%@\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[PYLServer formDataHeaderNamed:@"add_file"]];
    [postBody appendData:[@"Content-Type: application/octet-stream\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:newlineData];

	[postBody appendData:[[NSString stringWithFormat:@"\n--%@\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[PYLServer formDataHeaderNamed:@"add_dest"]];
	[postBody appendData:newlineData];
    [postBody appendData:[[NSString stringWithFormat:@"%d", destination] dataUsingEncoding:NSUTF8StringEncoding]];

    [postBody appendData:[[NSString stringWithFormat:@"\n--%@--\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [request setHTTPBody:postBody];
    [postBody release];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        PYLServerAssertConnection;
        
        // TODO: Check for success
    }];
}

- (void) fetchCoreConfig {
	NSMutableURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeFetchCoreConfig];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;
		
		NSError *e = nil;
		NSDictionary *config = [NSJSONSerialization JSONObjectWithData:data options:0 error:&e];
		
		BOOL throttledState = [[PYLServer configValueForName:@"limit_speed" inConfigSection:config[@"download"][@"items"]] boolValue];
		[_delegate server:self didChangeThrottledState:throttledState];
	}];
}

- (void) setThrottling:(BOOL)enabled {
	NSMutableURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeSetGeneralConfigKeyValuePair];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
 
	NSMutableData *postBody = [[NSMutableData alloc] init];
	[postBody appendData:[[NSString stringWithFormat:@"download%%7Climit_speed=%s", enabled ? "True" : "False"] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	[postBody release];
	
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;
		
		// TODO: Check for OK
		[_delegate server:self didChangeThrottledState:enabled];
	}];
}

- (void) setSpeedLimit:(NSUInteger)newLimit {
	NSMutableURLRequest *request = [self mutableRequestForRequestType:PYLRequestTypeSetGeneralConfigKeyValuePair];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
 
	NSMutableData *postBody = [[NSMutableData alloc] init];
	[postBody appendData:[[NSString stringWithFormat:@"download%%7Cmax_speed=%lu", newLimit] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	[postBody release];
	
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;
		
		// TODO: Check for OK
	}];
}

- (void) restartFileId:(NSUInteger)fileId {
	// NOTE: This one is a GET for some reason
	NSString *endpoint = [NSString stringWithFormat:@"/api/restartFile/%lu", fileId];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self urlWithLastPathComponent:endpoint]];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
		PYLServerAssertConnection;
		
		// TODO: Look for "true"
	}];
	[request release];
}

#pragma mark - Helper Methods

+ (NSData *)formDataHeaderNamed:(NSString *)name {
    NSString *stringData = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\n", name];
    return [stringData dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSArray *) logLinesFromLogHTML:(NSString *)html {
	// HACK: This is some super dirty scraping
	html = [[html componentsSeparatedByString:@"<table class=\"logtable\" cellpadding=\"0\" cellspacing=\"0\">"] lastObject];
	html = [[html componentsSeparatedByString:@"</table>"] firstObject];
	
	NSArray *lines = [html componentsSeparatedByString:@"\n</td></tr>\n"];
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:[lines count] - 1];
	
	for (NSString *line in lines) {
		NSArray *components = [line componentsSeparatedByString:@"</td><td"];
		
		if ([components count] == 4) {
			PYLLogLine *l = [[PYLLogLine alloc] init];
			
			l.timestamp = [components[1] substringFromIndex:1];
			l.importance = [components[2] substringFromIndex:18];
			l.text = [components[3] substringFromIndex:1];
			
			[result addObject:l];
			[l release];
		}
	}
	
	return [result autorelease];
}

+ (NSString *) configValueForName:(NSString *)name inConfigSection:(NSArray *)list {
	for (NSDictionary *entry in list) {
		if ([entry[@"name"] isEqualToString:name]) {
			return entry[@"value"];
		}
	}
	
	return nil;
}

#pragma mark - Item Correlation Methods

- (NSDictionary *) queueItemForPid:(NSUInteger)pid {
	__block NSUInteger index = NSNotFound;
	
	[_queue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if ([obj[@"pid"] integerValue] == pid) {
			index = idx;
			*stop = YES;
		}
	}];
	
    if (index != NSNotFound) {
        return _queue[index];
    }
    return nil;
}

- (NSDictionary *) downloadItemForFid:(NSUInteger)fid {
	__block NSUInteger index = NSNotFound;
	
	[_downloadList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if ([obj[@"fid"] integerValue] == fid) {
			index = idx;
			*stop = YES;
		}
	}];
	
    if (index != NSNotFound) {
        return _downloadList[index];
    }
    return nil;
}

@end
