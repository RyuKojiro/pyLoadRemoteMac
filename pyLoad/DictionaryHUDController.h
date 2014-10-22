//
//  DictionaryHUDController.h
//  pyLoad
//
//  Created by Daniel Loffgren on 10/21/14.
//  Copyright (c) 2014 Daniel Loffgren. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DictionaryHUDController;

@protocol DictionaryHUDDelegate <NSObject>

- (void) dictionaryHUDWillClose:(DictionaryHUDController *)controller;

@end

@interface DictionaryHUDController : NSWindowController

@property (retain) NSDictionary *dictionary;
@property (assign) id <DictionaryHUDDelegate> delegate;

@end
