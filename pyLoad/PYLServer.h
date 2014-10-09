//
//  PYLServer.h
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PYLServer;

@protocol PYLServerDelegate <NSObject>

- (void) serverConnected:(PYLServer *)server;
- (void) server:(PYLServer *)server didRefreshDownloadList:(NSArray *)list;
- (void) serverHasCaptchaWaiting:(PYLServer *)server;
- (void) server:(PYLServer *)server didUpdateFreeSpace:(NSUInteger)bytesFree;

@end

typedef enum {
	PYLRequestTypeNone,
	PYLRequestTypeLogin,
	PYLRequestTypeFetchDownloadsList,
	PYLRequestTypeCheckForCaptcha,
	PYLRequestTypeCheckFreeSpace
} PYLRequestType;

@interface PYLServer : NSObject

@property (copy) NSString *address;
@property (readwrite) NSUInteger port;
@property (copy) NSString *username;
@property (readonly, getter=isConnected) BOOL connected;
@property (readonly) NSArray *downloadList;
@property (assign) id <PYLServerDelegate> delegate;

- (instancetype) initWithAddress:(NSString *)address port:(NSUInteger)port;
- (void) connectWithUsername:(NSString *)username password:(NSString *)password;
- (void) disconnect;

- (void) refreshDownloadList;
- (void) checkForCaptcha;
- (void) checkFreeSpace;

+ (PYLRequestType) requestTypeForRequest:(NSURLRequest *)req;
- (NSMutableURLRequest *) mutableRequestForRequestType:(PYLRequestType)type;

@end
