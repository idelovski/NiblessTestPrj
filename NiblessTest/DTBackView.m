//
//  BackView.m
//  EventMonitor
//
//  Created by me on Fri Nov 02 2001.
//  Copyright (c) 2023 Delovski d.o.o. All rights reserved.
//

#import  "DTBackView.h"


@implementation DTBackView

- (BOOL)acceptsFirstResponder
{
    return (YES);
}

- (BOOL)becomeFirstResponder
{
    [self setNeedsDisplay:YES];
   
    return ([super becomeFirstResponder]);
}

- (BOOL)resignFirstResponder
{
   [self setNeedsDisplay:YES];
   
   return ([super resignFirstResponder]);
}

- (BOOL)isFirstResponder
{
   if (![[self window] isKeyWindow])
      return (NO);
   if ([[self window] firstResponder] == self)
      return (YES);
   
   return (NO);
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
   NSLog (@"acceptsFirstMouse [Back]: NOPE!");
   
   return (NO);
}

- (BOOL)isFlipped
{
   return (YES);
}

#pragma mark -

- (void)drawRect:(NSRect)dirtyRect
{
   NSWindow  *win = self.window;
   FORM_REC  *form = id_FindForm (win);
   
   id_DrawTBPadding (form);
   
   // NSLog (@".");
}

#pragma mark -

- (void)handleToolbar:(id)sender
{
   NSButton  *btn = (NSButton *)sender;
   
   NSLog (@"Toolbar Button: %d", (int)btn.tag);
}

- (void)onScaleSelectionChange:(id)sender
{
   NSPopUpButton  *btn = (NSPopUpButton *)sender;
   NSWindow       *win = self.window;
   CGRect          winRect = win.frame;
   FORM_REC       *form = id_FindForm (win);
   
   NSLog (@"Toolbar PopUp Button: %d: %d %%", (int)btn.tag, (int)[btn.selectedItem.title intValue]);
   
   short  oldRatio = form->scaleRatio;
   
   CGRect   origRect = CGRectMake (winRect.origin.x, winRect.origin.y, winRect.size.width * 100 / oldRatio, winRect.size.height * 100 / oldRatio);

   short  ratio = 100 + 10 * btn.indexOfSelectedItem;
   
   CGRect  newRect = CGRectMake (origRect.origin.x, origRect.origin.y, origRect.size.width * ratio / 100, origRect.size.height * ratio / 100);
   
   // win.frame = newRect;
   
   newRect.origin.y -= newRect.size.height - winRect.size.height;
   
   [win setFrame:newRect display:YES animate:YES];
   
   form->overlayView.frame = ((NSView *)[self.window contentView]).frame;
   
   [self resizeContentInForm:form toNewRatio:ratio];
   
   form->scaleRatio = ratio;
}

- (void)resizeContentInForm:(FORM_REC *)form toNewRatio:(short)ratio
{
   [MainLoop resizeControl:form->okButton inForm:form toNewRatio:ratio];
   [MainLoop resizeControl:form->newWinButton inForm:form toNewRatio:ratio];
   
   [MainLoop resizeControl:form->imgButton inForm:form toNewRatio:ratio];
   [MainLoop resizeControl:form->imgView inForm:form toNewRatio:ratio];
   
   [MainLoop resizeControl:form->checkBoxButton inForm:form toNewRatio:ratio];

   [MainLoop resizeControl:form->radioButton[0] inForm:form toNewRatio:ratio];
   [MainLoop resizeControl:form->radioButton[1] inForm:form toNewRatio:ratio];
   [MainLoop resizeControl:form->radioButton[2] inForm:form toNewRatio:ratio];

   [MainLoop resizeControl:form->leftField inForm:form toNewRatio:ratio];
   [MainLoop resizeControl:form->rightField inForm:form toNewRatio:ratio];
   [MainLoop resizeControl:form->bigField inForm:form toNewRatio:ratio];
   
   [MainLoop resizeControl:form->labelField inForm:form toNewRatio:ratio];
   
   [MainLoop resizeControl:form->popUpButtonL inForm:form toNewRatio:ratio];
   [MainLoop resizeControl:form->popUpButtonS inForm:form toNewRatio:ratio];
   [MainLoop resizeControl:form->popUpButtonR inForm:form toNewRatio:ratio];

   id_frame_fields (form, form->radioButton[0], form->radioButton[2], 0, NULL);
}

@end

