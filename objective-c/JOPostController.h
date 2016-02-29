//
//  JOPostPunchlineController.h
//  JokeOff
//
//  Created by Serge Kutny on 10/4/11.
//  Copyright 2011 BITP. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JOViewController.h"
#import "JOKeyboardController.h"
#import "JOTextView.h"
#import "JOBaseModel.h"
#import "JOOverlayDelegate.h"
#import "JOImageView.h"
#import "JOSubmitter.h"
#import "JOModelBase.h"
#import "JOCarouselItem.h"
#import "JOChildOfTopViewController.h"

extern NSString * const kPostCompleteNotification;

@class JOJoke;

@protocol JOPostDelegate<NSObject>

@property(nonatomic, assign) BOOL shouldShareToFacebook;
@property(nonatomic, assign) BOOL shouldShareToTwitter;
@property(nonatomic, assign) BOOL shouldPostAnonymously;

@optional
-(void)postContent:(NSString*)content;
-(void)postContent:(NSString*)content withPictures:(NSMutableArray*)pictures;

@end


@interface JOPostController : JOKeyboardController<UITextViewDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate,JOBaseModelDelegate, JOOverlayDelegate,JOSubmitter,JOCarouselItem,JOChildOfTopViewController>
{
    JOTextView * contentInput;
    NSMutableArray * pictures;
}

@property(nonatomic, retain) NSMutableArray * pictures;

@property (nonatomic, retain) JOJoke * joke;

@property(nonatomic, retain) IBOutlet UIView * footerView;

@property(nonatomic, retain) IBOutlet JOImageView * avatarView;

@property(nonatomic, retain) IBOutlet JOTextView * contentInput;

@property(nonatomic, retain) IBOutlet UIButton * fbToggler;

@property(nonatomic, retain) IBOutlet UIButton * fbIcon;

@property(nonatomic, retain) IBOutlet UIButton * anonymToggler;

@property(nonatomic, retain) IBOutlet UIButton * albumToggler;

@property(nonatomic, retain) IBOutlet UIButton * attachToggler;

@property(nonatomic, retain) IBOutlet UIButton * cameraToggler;

@property(nonatomic, retain) IBOutlet UILabel * charCountLabel;

-(IBAction)toggleFacebook:(id)sender;
-(IBAction)toggleAnonymous:(id)sender;
-(IBAction)toggleAlbum:(id)sender;
-(IBAction)toggleAttach:(id)sender;

@end
