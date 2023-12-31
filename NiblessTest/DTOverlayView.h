//
//  DTOverlayView.h
//  NiblessTest
//
//  Created by me on Aug 24 2023.
//  Copyright (c) 2023 Delf. All rights reserved.
//

#import  <AppKit/AppKit.h>
#import  <QuartzCore/QuartzCore.h>

#import  "MainLoop.h"
#import  "WindowFactory.h"

@interface  DTOverlayView : NSView
{
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;

@end

@interface NSColor(Additions)
- (CGColorRef)toCGColor;
@end

int  id_GetPort (FORM_REC *form, WindowPtr *savedPort);
int  id_SetPort (FORM_REC *form, WindowPtr whichPort);

void id_FrameRoundRect (FORM_REC *form, Rect *theRect);
void id_FrameRect (FORM_REC *form, Rect *theRect);
int  id_FrameCard (FORM_REC *form, short fromLeft);

void  id_FrameEditRect (FORM_REC *form, Rect *theRect);  // context must be available
void  id_InvalWinRect (FORM_REC *form, Rect *invalRect);
