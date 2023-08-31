//
//  DTBackView.h
//  dTOOL
//
//  Created by me on Aug 11 2023.
//  Copyright (c) 2023 Delf. All rights reserved.
//

#import  <AppKit/AppKit.h>

#import  "MainLoop.h"
#import  "WindowFactory.h"

@interface  DTBackView : NSView
{
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;

- (void)handleToolbar:(id)sender;

@end
