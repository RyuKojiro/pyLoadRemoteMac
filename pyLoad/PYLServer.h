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

- (void) server:(PYLServer *)server didRefreshDownloadList:(NSArray *)list;

@end

typedef enum {
	PYLServerStateIdle,
	PYLServerStateError,
	PYLServerStateLoggingIn,
	PYLServerStateFetchingDownloadsList,
} PYLServerState;

@interface PYLServer : NSObject

@property (copy) NSString *address;
@property (readwrite) NSUInteger port;
@property (copy) NSString *username;
@property (readonly, getter=isConnected) BOOL connected;
@property (readonly) PYLServerState state;
@property (readonly) NSArray *downloadList;
@property (assign) id <PYLServerDelegate> delegate;

- (instancetype) initWithAddress:(NSString *)address port:(NSUInteger)port;
- (void) connectWithUsername:(NSString *)username password:(NSString *)password;
- (void) disconnect;

- (void) refreshDownloadList;

+ (NSString *)extensionForString:(NSString *)file;

@end