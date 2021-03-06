//
//  PYLServer.h
//  pyLoad
//
//  Created by Daniel Loffgren on 10/8/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import <AppKit/AppKit.h> // Captcha needs NSImage
#import <Foundation/Foundation.h>

@class PYLServer;

@protocol PYLServerDelegate <NSObject>

- (void) serverConnected:(PYLServer *)server;
- (void) serverDisconnected:(PYLServer *)server;
- (void) server:(PYLServer *)server didRefreshDownloadList:(NSArray *)list;
- (void) server:(PYLServer *)server didRefreshQueue:(NSArray *)queue;
- (void) serverHasCaptchaWaiting:(PYLServer *)server;
- (void) server:(PYLServer *)server didUpdateFreeSpace:(NSUInteger)bytesFree;
- (void) server:(PYLServer *)server didUpdateSpeed:(CGFloat)bytesPerSec;
- (void) server:(PYLServer *)server didUpdatePausedStatus:(BOOL)paused;
- (void) server:(PYLServer *)server didRefreshLogs:(NSArray *)logData;
- (void) server:(PYLServer *)server didUpdateActiveCount:(NSUInteger)active queueCount:(NSUInteger)queueCount totalCount:(NSUInteger)totalCount;
- (void) server:(PYLServer *)server didChangeThrottledState:(BOOL)throttlingEnabled;

@end

typedef enum {
	PYLRequestTypeNone,
	PYLRequestTypeLogin,
	PYLRequestTypeFetchDownloadsList,
	PYLRequestTypeFetchQueue,
	PYLRequestTypeCheckForCaptcha,
	PYLRequestTypeCheckFreeSpace,
	PYLRequestTypeRestartFailed,
	PYLRequestTypeUpdateStatus,
	PYLRequestTypeFetchCaptcha,
	PYLRequestTypeSubmitCaptcha,
	PYLRequestTypePauseServer,
	PYLRequestTypeUnpauseServer,
	PYLRequestTypeCancelAll,
	PYLRequestTypeFetchLogs,
    PYLRequestTypeAddPackage,
	PYLRequestTypeSetGeneralConfigKeyValuePair,
	PYLRequestTypeFetchCoreConfig
} PYLRequestType;

typedef enum {
    PYLDestinationNone,
    PYLDestinationQueue = 1,
    PYLDestinationCollector = 2
} PYLDestination;

@interface PYLServer : NSObject

@property (copy) NSString *address;
@property (readwrite) NSUInteger port;
@property (copy) NSString *username;
@property (readonly, getter=isConnected) BOOL connected;
@property (readonly) NSArray *downloadList;
@property (readonly) NSArray *queue;
@property (assign) id <PYLServerDelegate> delegate;
@property (readonly, getter=isLocal) BOOL local;

- (instancetype) initWithRemoteAddress:(NSString *)address port:(NSUInteger)port;
- (instancetype) initWithLocalPath:(NSString *)pathToPyloadBinaries usingPython:(NSString *)pathToPython;

- (void) connectWithUsername:(NSString *)username password:(NSString *)password;
- (void) connectLocally;
- (void) disconnect;

- (void) refreshDownloadList;
- (void) refreshQueue;

- (void) checkForCaptcha;
- (void) checkFreeSpace;
- (void) restartFailed;
- (void) updateStatus;

- (void) fetchCaptchaWithCompletionHandler:(void (^)(NSUInteger captchaId, NSImage *image))handler;
- (void) submitCaptchaSolution:(NSString *)solution forCaptchaId:(NSUInteger)captchaId;

- (void) pauseServer;
- (void) unpauseServer;

- (void) addPacakgeNamed:(NSString *)packageName withLinks:(NSString *)newlineSeparatedLinks password:(NSString *)password destination:(PYLDestination)destination;

- (void) restartFileId:(NSUInteger)fileId;
- (void) cancelLinkId:(NSUInteger)linkId;
- (void) cancelAllLinks;

- (void) removePackageId:(NSUInteger)packageId;
- (void) removeAllCompletePackages;

- (void) fetchCoreConfig;
- (void) setThrottling:(BOOL)enabled;
- (void) setSpeedLimit:(NSUInteger)newLimit;

- (void) fetchLogs;

- (NSDictionary *) queueItemForPid:(NSUInteger)pid;
- (NSDictionary *) downloadItemForFid:(NSUInteger)fid;

+ (PYLRequestType) requestTypeForRequest:(NSURLRequest *)req;
- (NSMutableURLRequest *) mutableRequestForRequestType:(PYLRequestType)type;

@end
