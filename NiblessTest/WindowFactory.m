//
//  WindowFactory.m
//  NiblessTest
//
//  Created by me on 16.08.23.
//  Copyright 2023 Delovski d.o.o. All rights reserved.
//

#import  "WindowFactory.h"
#import  "MainLoop.h"
#import  "GetNextEvent.h"

@implementation  WindowFactory

@synthesize  window;

// TO DO!
// Well, this windowFactory should be allocated for each window
// as it has KVO for a window so one instance can't observe all the windows out there


- (id)initWithWindow:(NSWindow *)aWindow;  // Should I have this for each window and why? dont need this property
{
   if (self = [super init])  {
      self.window = aWindow;
      // self.menuDict = [NSMutableDictionary dictionary];
      
      [aWindow addObserver:self
                forKeyPath:@"firstResponder"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
   }
   
   return (self);
}

+ (NSWindow *)createWindowWithRect:(CGRect)wFrame
                         withTitle:(NSString *)wTitle
{
   NSUInteger  style = NSClosableWindowMask | NSMiniaturizableWindowMask;
   
   if (wTitle)
      style |= NSTitledWindowMask;

   // if ([isTextured state] == NSOnState)
   //   style |= NSTexturedBackgroundWindowMask;

   // NSRect frame = [[sender window] frame];
   
   // frame.origin.x += (((double)random()) / LONG_MAX) * 200;
   // frame.origin.y += (((double)random()) / LONG_MAX) * 200;
   
   NSWindow  *win = [[NSWindow alloc] initWithContentRect:wFrame
                                                styleMask:style
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
   [win setOpaque:YES];  // Default is NO
   [win setAlphaValue:1.];
   [win setBackgroundColor:[NSColor whiteColor]];
   
   [win setHasShadow:NSOnState];
   
	[win setAcceptsMouseMovedEvents: YES];

   if (wTitle)
      [win setTitle:wTitle];
   // [win makeKeyAndOrderFront:self];  // NSApp or me?  -- do it outside or pass a delegate in here
   
   return (win);
}

- (void)dealloc
{
   [window removeObserver:self forKeyPath:@"firstResponder"];

   [window release];
   
   [super dealloc];
}

#pragma mark -

- (void)dtButtonPressed:(NSButton *)aButton
{
   FORM_REC  *form = id_FindForm (aButton.window);
   
   if (form)
      form->retValue = (int)aButton.tag;
}

#pragma mark -

- (BOOL)handleCurrentFieldChange:(NSTextField *)textField
{
   FORM_REC  *form = id_FindForm (textField.window);
   
   if (form)  {
      form->cur_fldno = textField.tag - 1;
      NSLog (@"Current field: %hd", form->cur_fldno);
      
      if ((textField != form->leftField) && (form->prev_cur_fldno == form->leftField.tag - 1))  {
         if ([form->leftField.stringValue isEqual:@"NoExit"])
            [form->leftField becomeFirstResponder];
      }
   }
   
   return (YES);
}

- (void)handleFirstResponderChange:(NSResponder *)newFirstResponder
{
   if ([newFirstResponder isKindOfClass:[NSTextView class]]) {
      NSTextView  *textView = (NSTextView *)newFirstResponder;
      if ([textView.delegate isKindOfClass:[NSTextField class]])  {
         NSTextField  *textField = (NSTextField *)textView.delegate;
         
         NSLog (@"NSTextField gained input focus");
         WindowFactory  *wf = (WindowFactory *)textField.delegate;
         
         [wf handleCurrentFieldChange:textField];
      }
   }
}

// KVO callback method
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
   // if (change)
   //    NSLog (@"observeValueForKeyPath: change: %@", change);

   if ([keyPath isEqualToString:@"firstResponder"])  {
      NSResponder  *firstResponder = self.window.firstResponder;
      
      if ([firstResponder isKindOfClass:[NSTextField class]]) {
         NSTextField  *field = (NSTextField *)firstResponder;
         NSLog (@"WUHU! NSTextField gained input focus: %@", field.stringValue);
      }
      else  if ([firstResponder isKindOfClass:[NSTextView class]]) {
         NSTextView  *textView = (NSTextView *)firstResponder;
         /*if ([textView.delegate isKindOfClass:[NSTextField class]]) {
            NSLog(@"NSTextField gained input focus");
         }
         else  {
            NSLog (@"observeValueForKeyPath: delegate: %@ %@", textView.delegate, [textView.delegate class]);
         }*/
         /*if ([textView.nextResponder isKindOfClass:[NSTextField class]]) {
            NSLog(@"NSTextField gained input focus");
         }
         else  {
            NSLog (@"observeValueForKeyPath: nextResponder: %@ %@", textView.nextResponder, [textView.nextResponder class]);
         }*/
         // At this point delegate is nil
         [self performSelector:@selector(handleFirstResponderChange:)
                    withObject:textView
                    afterDelay:.001]; // Adjust delay as needed         
      }
      else
         NSLog (@"observeValueForKeyPath: %@ %@", firstResponder, [firstResponder class]);
   }
}

#pragma mark -

extern  FORM_REC  *dtRenderedForm;

- (BOOL)windowShouldClose:(id)sender
{
   NSWindow  *aWindow = (NSWindow *)sender;
   
   NSLog (@"windowShouldClose: %@ %d", aWindow.title, (int)aWindow.windowNumber);
   
   if (![aWindow isDocumentEdited])
      return (YES);
   
   return (NO);
}

// This needs to create an EventRecord that will produce:
// 1) mouseDown
// 2) FindWindow() should set partWind == inGoAway & WindowPtr of my NSWindow
// ... and FindWindow() must become id_FindWindow in both Carbon & Cocoa

- (void)windowWillClose:(NSNotification *)aNotification;
{
   NSWindow  *aWindow = (NSWindow *)[aNotification object];
   FORM_REC  *form = id_FindForm (aWindow);
   
   if (form == dtRenderedForm)  {
      id_FlushUsedEvents (form);
      id_release_form (form);
   }
   
   if (form)  {
      if ((form->w_procID == movableDBoxProc) || (form->w_procID == dBoxProc) ||
          (form->w_procID == plainDBox))  {
         dtGData->modalFormsCount--;
         if (form->modalSession)
            [NSApp endModalSession:form->modalSession];
         form->modalSession = NULL;
      }
   }

   id_BuildCloseWindowEvent (form, NULL);
   
   
   NSLog (@"windowWillClose: %@ %d", aWindow.title, (int)aWindow.windowNumber);
}

#pragma mark -

- (void)windowDidExpose:(NSNotification *)aNotification
{
   NSLog (@"windowDidExpose:");
}

- (void)windowWillMove:(NSNotification *)aNotification
{
   NSLog (@"windowWillMove:");
}

- (void)windowDidMove:(NSNotification *)aNotification
{
   NSLog (@"windowDidMove:");
}

- (void)windowDidResize:(NSNotification *)aNotification
{
   NSLog (@"windowDidResize:");
}

- (void)windowDidMiniaturize:(NSNotification *)aNotification
{
   NSLog (@"windowDidMiniaturize:");
}

- (void)windowDidDeminiaturize:(NSNotification *)aNotification
{
   NSLog (@"windowDidDeminiaturize:");
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
   NSWindow  *aWindow = (NSWindow *)[aNotification object];
   FORM_REC  *form = id_FindForm (aWindow);

   NSLog (@"windowDidBecomeKey: [%@]", form ? aWindow.title : @"No name");
   
   id_printWindowsOrder ();
   
   if (form && form->my_window)
      id_BuildActivateEvent (form, TRUE);
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
   NSWindow  *aWindow = (NSWindow *)[aNotification object];
   FORM_REC  *form = id_FindForm (aWindow);

   NSLog (@"windowDidResignKey: [%@]", form ? aWindow.title : @"No name");
   
   if (form && form->my_window)
      id_BuildActivateEvent (form, FALSE);
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification;
{
   NSWindow  *aWindow = (NSWindow *)[aNotification object];
   FORM_REC  *form = id_FindForm (aWindow);
   
   NSLog (@"windowDidBecomeMain: [%@]", form ? aWindow.title : @"No name");
   
   FrontWindow ();
   
   /*if (form && form->parentForm)  {
      // [form->parentForm->my_window orderWindow:NSWindowBelow relativeTo:[aWindow windowNumber]];
      [aWindow orderWindow:NSWindowAbove relativeTo:[form->parentForm->my_window windowNumber]];
   }*/
}

- (void)windowDidUpdate:(NSNotification *)aNotification;
{
   NSWindow  *aWindow = (NSWindow *)[aNotification object];
   FORM_REC  *form = id_FindForm (aWindow);
   
   // This is too chatty, can't see anything else because of this
   // NSLog (@"windowDidUpdate: [%@]", form ? aWindow.title : @"No name");
}

- (void)windowDidChangeBackingProperties:(NSNotification *)aNotification
{
   NSLog (@"windowDidChangeBackingProperties:");
}

- (void)windowDidChangeScreenProfile:(NSNotification *)aNotification
{
   NSLog (@"windowDidChangeScreenProfile:");
}

- (void)windowWillEnterFullScreen:(NSNotification *)aNotification
{
   NSLog (@"windowWillEnterFullScreen:");
}

- (void)windowDidFailToEnterFullScreen:(NSNotification *)aNotification
{
   NSLog (@"windowDidFailToEnterFullScreen:");
}

- (void)windowWillExitFullScreen:(NSNotification *)aNotification
{
   NSLog (@"windowWillExitFullScreen:");
}

- (void)windowDidFailToExitFullScreen:(NSNotification *)aNotification
{
   NSLog (@"windowDidFailToExitFullScreen:");
}

- (void)windowDidExitFullScreen:(NSNotification *)aNotification
{
   NSLog (@"windowDidExitFullScreen:");
}

#pragma mark -

- (void)keyDown:(NSEvent *)theEvent
{
   NSLog (@"keyDown:");
}
- (void)keyUp:(NSEvent *)theEvent
{
   NSLog (@"keyUp:");
}

- (BOOL)processHitTest:(NSEvent *)theEvent
{
   NSLog (@"processHitTest:");

   return (NO);  /* not a special area, carry on. */
}

- (void)mouseDown:(NSEvent *)theEvent
{
   NSLog (@"mouseDown:");
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
   NSLog (@"rightMouseDown:");

   [self mouseDown:theEvent];
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
   NSLog (@"otherMouseDown:");
   
   [self mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
   NSLog (@"mouseUp:");
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
   NSLog (@"rightMouseUp:");

   [self mouseUp:theEvent];
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
   NSLog (@"otherMouseUp:");

   [self mouseUp:theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
   NSLog (@"mouseMoved:");
}

- (void)mouseDragged:(NSEvent *)theEvent;
{
   NSLog (@"mouseDragged:");

   [self mouseMoved:theEvent];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
   NSLog (@"rightMouseDragged:");

   [self mouseMoved:theEvent];
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
   NSLog (@"otherMouseDragged:");

   [self mouseMoved:theEvent];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
   NSLog (@"scrollWheel:");
}

- (void)touchesBeganWithEvent:(NSEvent *)theEvent
{
   NSLog (@"touchesBeganWithEvent:");
}

- (void)touchesMovedWithEvent:(NSEvent *)theEvent
{
   NSLog (@"touchesMovedWithEvent:");
   
   [self handleTouches:NSTouchPhaseMoved withEvent:theEvent];
}

- (void)touchesEndedWithEvent:(NSEvent *)theEvent
{
   NSLog (@"touchesEndedWithEvent:");

   [self handleTouches:NSTouchPhaseEnded withEvent:theEvent];
}

- (void)touchesCancelledWithEvent:(NSEvent *)theEvent
{
   NSLog (@"touchesCancelledWithEvent:");

   [self handleTouches:NSTouchPhaseCancelled withEvent:theEvent];
}

- (void)handleTouches:(NSTouchPhase)phase withEvent:(NSEvent *)theEvent
{
   NSLog (@"touchesCancelledWithEvent:");

   // NSSet *touches = [theEvent touchesMatchingPhase:phase inView:nil];
}

#pragma mark -

- (void)setFieldEditor:(NSText *)fieldEditor
{
   NSLog (@"setFieldEditor: %@", fieldEditor.string);
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor;
{
   NSTextField  *textField = (NSTextField *)control;
   NSEvent      *event = [NSApp currentEvent];

   NSLog (@"control:textShouldBeginEditing = '%@' -> '%@' / '%@'",
          (event.type == NSKeyDown) ? event.characters : @"º",
          [textField stringValue], fieldEditor.string);

   return (YES);
}

// This is called only if dirty

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor;
{
   NSLog (@"control:textShouldEndEditing: %@", fieldEditor.string);
   
   return (YES);
}

- (BOOL)     control:(NSControl *)control
            textView:(NSTextView *)textView
 doCommandBySelector:(SEL)commandSelector
{
   BOOL  result = NO;

   if ([control isKindOfClass:[NSTextField class]])
      NSLog (@"control:textView:doCommandBySelector: [NSTextField]");
      
   if (commandSelector == @selector(insertNewline:))  {
      //Do something against ENTER key
      NSLog (@"control:textView:doCommandBySelector: insertNewline");
      [textView insertNewlineIgnoringFieldEditor:self];  // or self
      result = YES;
   }
   else if (commandSelector == @selector(deleteForward:))  {
      //Do something against DELETE key
      NSLog (@"control:textView:doCommandBySelector: deleteForward");
   }
   else if (commandSelector == @selector(deleteBackward:))  {
      //Do something against BACKSPACE key
      NSLog (@"control:textView:doCommandBySelector: deleteBackward");
   }
   else if (commandSelector == @selector(insertTab:))  {
      //Do something against TAB key
      NSLog (@"control:textView:doCommandBySelector: insertTab");
      
      // result = YES; to handle it on my own
      // or...
      // [[textView window] selectNextKeyView:nil];  return (YES);
   }
   
   return (result);
}

#pragma mark -

- (BOOL)textShouldBeginEditing:(NSText *)textObject;
{
   NSLog (@"textShouldBeginEditing:");
   
   return (YES);
}

// Useless

- (BOOL)textShouldEndEditing:(NSText *)textObject;
{
   NSLog (@"textShouldEndEditing:");

   return (YES);
}

- (void)textDidChange:(NSNotification*)notification
{
   NSLog (@"textDidChange:");
}

/*---------------------------------------------------------------------------*/

- (void)textDidBeginEditing:(NSNotification *)notification
{
   NSLog (@"textDidBeginEditing:");
}

/*---------------------------------------------------------------------------*/

- (void)textDidEndEditing:(NSNotification*)notification
{
   NSLog (@"textDidEndEditing:");
}

#pragma mark -

// I have this id_check_chr_edit() that is dealing with a last typed char and I can't use it here
// There's no way to know what was the last typed char as the cursor may be in the middle of the text
// So, id_check_chr_edit() has to be split into several parts
// a) Size, if new text is too big return the old text I have in ditl_def
// b) Allowed chars ... well, go from strt to finsh, what can I do?
// c) Toupper, tolower, well, from start to finish
// d) Newline...? What if cursor is already in new line? As I remove it, what happens? Maybe a hook in GetNextEvent?
// e) 


- (void)controlTextDidChange:(NSNotification *)notification
{
   int    cpt = 0;
   short  selStart, selEnd;
   
   NSTextField  *textField = [notification object];
   
   NSEvent  *event = [NSApp currentEvent];
   
   if (event && (event.type == NSKeyDown))  {
      char  ch;
      
      if (event.modifierFlags & NSAlphaShiftKeyMask)  // See if this actually works - altKey, ctrlKey, cmdKey etc
         NSLog (@"controlTextDidChange - Shift key");
      if (event.modifierFlags & NSControlKeyMask)  // See if this actually works - altKey, ctrlKey, cmdKey etc
         NSLog (@"controlTextDidChange - Ctrl key");
      if (event.modifierFlags & NSAlternateKeyMask)  // See if this actually works - altKey, ctrlKey, cmdKey etc
         NSLog (@"controlTextDidChange - Alt key");
      if (event.modifierFlags & NSCommandKeyMask)  // See if this actually works - altKey, ctrlKey, cmdKey etc
         NSLog (@"controlTextDidChange - Cmd key");
         
      NSLog (@"controlTextDidChange - Key: '%@'", event.characters);
      
      if (!id_UniCharToChar([event.characters characterAtIndex:0], &ch))  {
         FORM_REC  *form = id_FindForm (textField.window);
         
         // Because I'm using the currentEvent it will hold Command-V so I should not bother with that
         // So, make extra validations elsewhere or modify this f() to handle changed text
         
         if (form)  {
            if (!(event.modifierFlags & NSCommandKeyMask) &&
                (id_check_chr_edit_char(form, textField.tag-1, ch) ||
                id_check_chr_edit_size(form, textField.tag-1, TExGetTextLen(textField))))  {
               char  *theText = id_field_text_buffer (form, textField.tag);
               short  txLen   = id_field_text_length (form, textField.tag);
               
               TExSetText (textField, theText, txLen);
            }
            else  if (form->ditl_def)  {
               char   tmpStr[256];
               short  len = 256;
               
               TExGetText (textField, tmpStr, &len);
               
               id_set_field_buffer_text (form, textField.tag, tmpStr, len);
            }
            return;
         }
      }
   }
   
   TExGetSelection (textField, &selStart, &selEnd);
   
   NSLog (@"controlTextDidChange: stringValue[%hd,%hd] = '%@' -> '%@'",
          selStart, selEnd,
          (event.type == NSKeyDown) ? event.characters : @"º",
          [textField stringValue]);
   
   NSCharacterSet  *charSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzŠĐČĆŽšđčćž#$%&?*\n "];
   
   unichar  *stringResult = malloc ([textField.stringValue length] * sizeof(unichar) + 1);
   
   for (int i = 0; i < [textField.stringValue length]; i++) {
      unichar c = [textField.stringValue characterAtIndex:i];
      if ([charSet characterIsMember:c]) {
         stringResult[cpt]=c;
         cpt++;
      }
   }
   stringResult[cpt]='\0';
   
   textField.stringValue = [NSString stringWithCharacters:stringResult length:cpt];
   
   free (stringResult);
   
   [textField.window setDocumentEdited:YES];
}

- (void)controlTextDidBeginEditing:(NSNotification *)notification;
{
   NSTextField  *textField = [notification object];
   
   NSLog (@"controlTextDidBeginEditing: stringValue = '%@'", [textField stringValue]);
   
   // [control setFieldEditor:]
}

// Called twice, first time window is firstResponder, next time the TextField in question, makes no sense
// Aha, if I Tab first Win becomes firstResponder, but if use the mouse, then nope, calle only once for text field as first responder

- (void)controlTextDidEndEditing:(NSNotification *)notification;
{
   NSTextField  *textField = [notification object];
   
   NSLog (@"56: stringValue = '%@'", [textField stringValue]);
   
   if ([self isTextFieldInFocus:textField])  {
      FORM_REC  *form = id_FindForm (textField.window);
      
      if (form && (form->cur_fldno == textField.tag - 1))
         form->prev_cur_fldno = textField.tag - 1;
   }
}

#pragma mark -

- (BOOL)isTextFieldInFocus:(NSTextField *)textField
{
	BOOL  inFocus = NO;
   
   NSResponder  *firstResponder = [[textField window] firstResponder];

   BOOL  rightClass = [[[textField window] firstResponder] isKindOfClass:[NSTextView class]];
   BOOL  isEqual = [textField isEqualTo:(id)[(NSTextView *)[[textField window] firstResponder]delegate]];

   NSText  *nsText1 = [[textField window] fieldEditor:NO forObject:nil];
   NSText  *nsText2 = [[textField window] fieldEditor:NO forObject:textField];
   Class    class = [firstResponder class];
	
	inFocus = ([[[textField window] firstResponder] isKindOfClass:[NSTextView class]]
              && [[textField window] fieldEditor:NO forObject:nil]!=nil
              && [textField isEqualTo:(id)[(NSTextView *)[[textField window] firstResponder]delegate]]);
	
	return inFocus;
}

#ifdef _NIJE_
- (void)textFieldDidBeginEditing:(NSNotification *)notification;
{
   NSTextField  *textField = [notification object];
   
   NSLog (@"textFieldDidBeginEditing: stringValue = '%@'", [textField stringValue]);
}
#endif

@end
