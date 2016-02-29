//
//  JOPostPunchlineController.m
//  JokeOff
//
//  Created by Serge Kutny on 10/4/11.
//  Copyright 2011 BITP. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "JOPostController.h"
#import "JOJoke.h"
#import "JokeOffAppDelegate.h"
#import "JOUser.h"
#import "JOAPI.h"
#import "Facebook.h"
#import "JSON.h"
#import "JOPunchline.h"
#import "JOSettingsController.h"
#import "JOMediaListController.h"
#import "JOSettings.h"
#import "JOLoadingController.h"
#import "JOFacebook.h"
#import <QuartzCore/QuartzCore.h>
#import "NSColor+RGB.h"

NSString * const kPostCompleteNotification = @"__POST_COMPLETE__";

@interface JOPostController ()

- (void)applyAnonymous:(BOOL)value;
- (void)attemptPresentPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType;
- (void)presentPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType;
- (void)presentMediaListController;
- (void)updatedAttachedImagesButtonState;

@property (nonatomic, retain) JOLoadingController * loadingController;

@end

@implementation JOPostController

@synthesize contentInput;
@synthesize fbToggler;
@synthesize avatarView;
@synthesize footerView;
@synthesize anonymToggler;
@synthesize charCountLabel;
@synthesize cameraToggler;
@synthesize albumToggler;
@synthesize attachToggler;
@synthesize pictures;
@synthesize loadingController;
@synthesize delegate;
@synthesize topViewController;
@synthesize joke;
@synthesize fbIcon;

- (void)dealloc 
{
	[contentInput release];
	[fbToggler release];
	[avatarView release];
    [anonymToggler release];
    [charCountLabel release];
    [footerView release];
    [albumToggler release];
    [attachToggler release];
    [cameraToggler release];
    self.fbIcon = nil;
    self.topViewController = nil;
    if ( self.joke ) 
    {
        self.joke.delegate = nil;
        self.joke = nil;
    }
    [super dealloc];
}

- (void)showLoadingView;
{
    self.loadingController = [JOLoadingController pushLoadingControllerToView:self.view];
    self.loadingController.label.text = @"Saving";
}

- (void)hideLoadingView;
{
    [loadingController.view removeFromSuperview];
    self.loadingController = nil;
}

- (void)resetForm;
{
    self.pictures = [NSMutableArray array];
    [contentInput setText:@""];
    [self updatedAttachedImagesButtonState];
}

- (void)didSubmit:(id)model;
{
    [self hideLoadingView];
    [self resetForm];
    if ( [delegate conformsToProtocol:@protocol(JOSubmitterDelegate)] ) 
    {
        [delegate submitter:self didSubmit:model];
    }
}

- (void)didChangeState:(id)model;
{
    [(JOModelBase*)model setIsFullFilled:YES];
    
    if ( [model facebookShared] )
    {
        [[JOFacebook sharedFacebook] share:model];
    }
    
    [self performSelectorOnMainThread:@selector(didSubmit:) 
                           withObject:model  
                        waitUntilDone:FALSE];
}

- (void)alertError:(NSError*)error;
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error occurred" 
                                                     message:[error localizedDescription]	 
                                                    delegate:self 
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
}

- (void)savingDidFail:(NSError*)error;
{
    [self hideLoadingView];
    [self alertError:error];
}

- (void)dataModel:(id)model didFail:(NSError *)error;
{
    [self performSelectorOnMainThread:@selector(savingDidFail:) 
                           withObject:error 
                        waitUntilDone:FALSE];
}

- (void)submitData;
{
    self.joke = [JOJoke joke];
    joke.content = contentInput.text;
    joke.delegate = self;
    joke.pictures = self.pictures;
    joke.anonymous = [[JOSettings defaultSettings] postAnonymously];
    joke.facebookShared = [[JOSettings defaultSettings] shareToFacebook];
    joke.author = [JOUser currentUser];
    [joke save];
}

- (void)submit;
{
	NSString * content = contentInput.text;
	if ( content.length )
	{
        [contentInput resignFirstResponder];
        [self showLoadingView];
        [self submitData];
	}
}

- (void)loadFooterView;
{
    if ( !self.footerView )
    {
        [[NSBundle mainBundle] loadNibNamed:@"JOPostFooter" 
                                      owner:self 
                                    options:nil];
        
        [self.view addSubview:self.footerView];
    }
}

- (void)addBorderAroundTextView;
{
    [[contentInput layer] setBorderColor:[[UIColor colorWithRGB:0x00008B] CGColor]];
    [[contentInput layer] setBorderWidth:1.3];
    [[contentInput layer] setCornerRadius:10];
    [contentInput setClipsToBounds: YES];    
}

- (void)viewDidLoad
{
	[super viewDidLoad];

    [self loadFooterView];
    
    self.pictures = [NSMutableArray array];
    
    [fbToggler setSelected:[[JOSettings defaultSettings] shareToFacebook]];
    [self applyAnonymous:[[JOSettings defaultSettings] postAnonymously]];
    
    [self addBorderAroundTextView];
}

- (void)viewDidUnload 
{
	self.contentInput = nil;
	self.fbToggler = nil;
	self.avatarView = nil;
    self.anonymToggler = nil;
    self.charCountLabel = nil;
    self.footerView = nil;
    self.albumToggler = nil;
    self.attachToggler = nil;
    self.cameraToggler = nil;
    self.fbIcon = nil;
    [super viewDidUnload];
}

- (void)didFocus;
{
    TESTFLIGHT_CHECKPOINT(@"Joke posting view is focused");
}

- (void)didUnFocus;
{
    [contentInput resignFirstResponder];
}

-(IBAction)toggleFacebook:(id)sender
{
    TESTFLIGHT_CHECKPOINT(@"Facebook sharing button is taped");
	[fbToggler setSelected:[[JOSettings defaultSettings] switchShareToFacebook]];
}

-(IBAction)toggleCamera:(id)sender
{
    TESTFLIGHT_CHECKPOINT(@"Camera button is taped");
    [self attemptPresentPickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera];
}

-(IBAction)toggleAlbum:(id)sender
{
    TESTFLIGHT_CHECKPOINT(@"Album button is taped");
    [self attemptPresentPickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

-(IBAction)toggleAttach:(id)sender
{
    TESTFLIGHT_CHECKPOINT(@"Attached images button is taped");
    [self presentMediaListController];
}

-(IBAction)toggleAnonymous:(id)sender;
{
    TESTFLIGHT_CHECKPOINT(@"Anonymous button is taped");
    [self applyAnonymous:[[JOSettings defaultSettings] switchPostAnonymously]];
}


#pragma mark -
#pragma mark - Image Picker Methods

- (void)updatedAttachedImagesButtonState;
{
    BOOL isEmpty = ( 0 == [pictures count] );
    
    if ( FALSE == isEmpty )
    {
        attachToggler.titleLabel.text = [NSString stringWithFormat:@"%d images", 
                                         [pictures count]];
    }
    
    attachToggler.hidden = isEmpty;
}

#pragma mark -
#pragma mark - UIResponder Methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
	UITouch * aTouch = [touches anyObject];
    
	if ( [attachToggler pointInside:[aTouch locationInView:attachToggler] withEvent:event] && attachToggler.hidden == NO )
	{
        [self toggleAttach:attachToggler];
    }
	else if ( [contentInput pointInside:[aTouch locationInView:contentInput] withEvent:event] )
	{
        if ( ![contentInput isFirstResponder] )
        {
            [contentInput becomeFirstResponder];
        }
    }
    else if( [contentInput isFirstResponder] )
    {
        [contentInput resignFirstResponder];
    }
}

#pragma mark -
#pragma mark - Image Picker Methods

- (void) presentMediaListController;
{
    JOMediaListController * mediaController = [[JOMediaListController alloc] initWithDataSource:pictures];
    
    [topViewController.navigationController pushViewController:mediaController 
                                         animated:TRUE];
    
    [mediaController release];
}

- (void)attemptPresentPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType;
{
    if ( [UIImagePickerController isSourceTypeAvailable:sourceType] )
    {
        [self presentPickerControllerWithSourceType:sourceType];
    }
}

- (void)presentPickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType;
{
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    
    picker.sourceType = sourceType;
    picker.allowsEditing = YES;
    picker.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
    picker.delegate = self;
    
    [topViewController presentModalViewController:picker 
                                         animated:YES];
}

- (void)dismissPickerController:(UIImagePickerController *)picker;
{
    [topViewController.navigationController dismissModalViewControllerAnimated:YES];
    
    [picker release];
}

- (void)writeImageToPhotoAlbum:(UIImage*)image;
{
    /*ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

    [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] 
                          completionBlock:^( NSURL * assetURL, NSError * error ) 
    {
        if ( ( nil == error ) && ( nil != assetURL ) )
        {
            [library assetForURL:assetURL resultBlock:^(ALAsset *asset) 
            {*/
                [self.pictures addObject:image];

                [self performSelectorOnMainThread:@selector(updatedAttachedImagesButtonState) 
                                       withObject:nil 
                                    waitUntilDone:FALSE];
                
            /*} failureBlock:^(NSError *error) 
            {
            }];*/
            
            //[self.pictures addObject:image]; // TO DO: Must be NSURL as link for an image
        /*}
    } ];
    
    [library release];*/
}

#pragma mark -
#pragma mark - UIImagePickerControllerDelegate Methods

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
{
    TESTFLIGHT_CHECKPOINT(@"Media picking is cancelled");
    [self dismissPickerController:picker];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
    TESTFLIGHT_CHECKPOINT(@"Finished media picking");
    NSString * mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    if ( CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo ) 
    {
        UIImage * editedImage = (UIImage *) [info objectForKey:UIImagePickerControllerEditedImage];
        UIImage * originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
        
        UIImage * imageToSave = ( editedImage ? editedImage : originalImage );
        [self writeImageToPhotoAlbum:imageToSave];
    }
    
    [self dismissPickerController:picker];
}

#pragma mark -

- (void)applyUserAvatar:(BOOL)isAnonymous;
{
    UIImage * image = nil;
    if ( isAnonymous ) 
    {
        image = [[JOUser anonymousUser] avatarImage];
    }
    else
    {
        image = [[JOUser currentUser] avatarImage];
    }
    avatarView.image = image;
}

- (void)applyAnonymous:(BOOL)value;
{
    [anonymToggler setSelected:value];
    [self applyUserAvatar:value];
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
}

- (CGRect)frameForOverlayView;
{
    return ( CGRectMake( 0, 0, self.view.frame.size.width, self.view.frame.size.height - 40 ) );
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
//	[self postContent:nil];

	return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
	NSString *newText = [contentInput.text 
						 stringByReplacingCharactersInRange:range withString:text];
    
    NSInteger charCount = newText.length;
	topViewController.navigationItem.rightBarButtonItem.enabled = !( [self.contentInput isEmptyWithText:newText] );
    
    if ( [delegate conformsToProtocol:@protocol(JOSubmitterDelegate)] ) 
    {
        [delegate submitter:self didChangeContent:[self.contentInput isEmptyWithText:newText]];
    }
    
    charCountLabel.text = [NSString stringWithFormat:@"%d", charCount];
    
	return YES;
}

@end
