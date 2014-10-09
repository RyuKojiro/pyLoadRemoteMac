//
//  PYLServer.h
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PYLServer : NSObject

@property (copy) NSString *address;
@property (readwrite) NSUInteger port;
@property (copy) NSString *username;
@property (readonly, getter=isConnected) BOOL connected;

- (instancetype) initWithAddress:(NSString *)address port:(NSUInteger)port;
- (void) connectWithUsername:(NSString *)username password:(NSString *)password;
- (void) disconnect;

@end
