//
//  PYLLogLine.h
//  pyLoad
//
//  Created by Daniel Loffgren on 10/10/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PYLLogLine : NSObject

@property (copy) NSString *timestamp;
@property (copy) NSString *importance;
@property (copy) NSString *text;

@end
