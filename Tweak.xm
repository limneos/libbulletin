#include "imports.h"
#include "JBBulletinManager.h"


@implementation JBBulletinManager{

	NSMutableArray *_attachmentImagesForIDs;
	NSMutableArray *_bundleImagesForIDs;
	NSMutableArray *_cachedLockscreenBulletins;
}

static JBBulletinManager *sharedJB=NULL;

+(id)sharedInstance{

	if (!sharedJB){
	
		sharedJB = [[self alloc] init];
		
	}
	return sharedJB;

}

-(id)init{
	
	if (self=[super init]){
		
		if (objc_getClass("SBAwayController")!=nil){
			_attachmentImagesForIDs = [[NSMutableArray alloc] init];
		}
		_bundleImagesForIDs			= [[NSMutableArray alloc] init];
		_cachedLockscreenBulletins 	= [[NSMutableArray alloc] init];
		sharedJB=self;
	}
	return self;

}

-(NSMutableArray *)cachedLockscreenBulletins{
	return _cachedLockscreenBulletins;
}

-(NSMutableArray *)attachmentImagesForIDs{
	return _attachmentImagesForIDs;
}

-(NSMutableArray *)bundleImagesForIDs{
	return _bundleImagesForIDs;
}

-(NSString *)newUUID{

	CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
	NSString *uuidStr = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject);
	CFRelease(uuidObject);
	return uuidStr;
	
}

-(id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage bundleID:(NSString *)inBundleID{

	// This displays a title and message and the bundleID's image
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:inBundleID hasSound:NO soundID:0 vibrateMode:0 soundPath:NULL attachmentImage:NULL overrideBundleImage:NULL];
}

-(id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage overrideBundleImage:(UIImage *)inOverridBundleImage{
	
	// This displays a title and message and the overrides the bundleID's expected image with the bundleImage supplied
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:NULL hasSound:NO soundID:0 vibrateMode:0 soundPath:NULL attachmentImage:NULL overrideBundleImage:inOverridBundleImage];
}

-(id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage bundleID:(NSString *)inBundleID soundPath:(NSString *)inSoundPath{

	// This displays a title and message and the bundleID's image and plays a sound from file
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:inBundleID hasSound:YES soundID:0 vibrateMode:0 soundPath:inSoundPath attachmentImage:NULL overrideBundleImage:NULL];
}

-(id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage bundleID:(NSString *)inBundleID soundID:(int)inSoundID{

	// This displays a title and message and the bundleID's image and plays a sound from a SystemSoundID
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:inBundleID hasSound:YES soundID:inSoundID vibrateMode:0 soundPath:NULL attachmentImage:NULL overrideBundleImage:NULL];
}

-(id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage overrideBundleImage:(UIImage *)inOverridBundleImage soundPath:(NSString *)inSoundPath{

	// This displays a title and message and the overrides the bundleID's expected image with the bundleImage supplied and plays a sound from file
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:NULL hasSound:YES soundID:0 vibrateMode:0 soundPath:inSoundPath attachmentImage:NULL overrideBundleImage:inOverridBundleImage];
}

-(id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage overridBundleImage:(UIImage *)inOverridBundleImage soundID:(int)inSoundID{

	// This displays a title and message and the overrides the bundleID's expected image with the bundleImage supplied and plays a sound from a SystemSoundID
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:NULL hasSound:YES soundID:inSoundID vibrateMode:0 soundPath:NULL attachmentImage:NULL overrideBundleImage:inOverridBundleImage];
}


-(id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage bundleID:(NSString *)inBundleID hasSound:(BOOL)hasSound soundID:(int)soundID vibrateMode:(int)vibrate soundPath:(NSString *)inSoundPath attachmentImage:(UIImage *)inAttachmentImage overrideBundleImage:(UIImage *)inOverrideBundleImage{
	
	__block NSString *title=[inTitle retain];
	__block NSString *message=[inMessage retain];
	__block NSString *soundPath=[inSoundPath retain];
	__block NSString *bundleID=[inBundleID retain];
	__block UIImage *attachmentImage=[inAttachmentImage retain];
	__block UIImage *overrideBundleImage=[inOverrideBundleImage retain];

	 
	__block BBBulletinRequest *request=[[objc_getClass("BBBulletinRequest") alloc] init]; //init here so we can return it
	
	 dispatch_async(dispatch_get_main_queue(),^{

		 
		request.section=bundleID;
		request.sectionID=bundleID;
		request.bulletinID=[self newUUID];
		request.bulletinVersionID=[self newUUID];
		request.recordID=[self newUUID];
		request.publisherBulletinID=[NSString stringWithFormat:@"-bulletin-manager-%@",[self newUUID]];
		request.title=title;
		request.message=message;
		request.date=[NSDate date] ;
		request.lastInterruptDate=[NSDate date] ;
		[request setClearable:YES];
		
		
		if (bundleID){
			BBAction *defaultAction =[objc_getClass("BBAction") actionWithLaunchBundleID:bundleID callblock:nil];
			[request setDefaultAction:defaultAction];
		}
		
		[title release];
		[message release];
		[bundleID release];
		
		if (overrideBundleImage){
			 
			[_bundleImagesForIDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:[overrideBundleImage copy],@"overrideBundleImage",[request bulletinID],@"bulletinID",NULL]];
			[overrideBundleImage release];
		}

		
		if (hasSound){ //behavior is 1 for vibrate , 0 for not (on soundIDS that don't vibrate by default)
			int playID=1015;
			if (soundID){
				playID=soundID;
			}
			BBSound *sound=NULL;
			if (soundPath){
				if ([objc_getClass("BBSound") instancesRespondToSelector:@selector(initWithSystemSoundPath:behavior:vibrationPattern:)]){
					sound=[[objc_getClass("BBSound") alloc] initWithSystemSoundPath:soundPath behavior:0 vibrationPattern:NULL];
				}
				else{
					CFURLRef fileURL = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)soundPath, kCFURLPOSIXPathStyle, false);
					SystemSoundID outSystemSoundID=0;
					AudioServicesCreateSystemSoundID ( fileURL, &outSystemSoundID );
					if (outSystemSoundID){
						sound=[[objc_getClass("BBSound") alloc] initWithSystemSoundID:outSystemSoundID behavior:vibrate vibrationPattern: NULL];
					}
					AudioServicesDisposeSystemSoundID(outSystemSoundID);
				}
				[soundPath release];
			}
			else{
				sound=[[objc_getClass("BBSound") alloc] initWithSystemSoundID:playID behavior:vibrate vibrationPattern: NULL];
			}
			
			
			[request setSound:sound];

		}
		
		
		if (attachmentImage){
		
			// resize attachment to a displayable size of (60,60) for new iOS or (38,38) for older
			
			if (objc_getClass("SBAwayController")!=nil){
				
				CGFloat height=attachmentImage.size.height;
				CGFloat width=attachmentImage.size.width;
				if (width>38 || height>38){
					CGFloat maxValue=MAX(width,height);
					CGFloat proportion=38/maxValue;
					attachmentImage=[attachmentImage _imageScaledToProportion:proportion interpolationQuality:5];
				}

			}
			else{
				attachmentImage=[attachmentImage imageResizedTo:CGSizeMake(60,60) preserveAspectRatio: YES];
			}
			
			[attachmentImage retain];
			BBAttachments *atts=[[objc_getClass("BBAttachments") alloc] init];
			[atts setPrimaryType:1];
			request.attachments=atts;
		}
			
		
		BOOL locked = objc_getClass("SBAwayController")!=nil ? [[objc_getClass("SBAwayController") sharedAwayController] isLocked] : [[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] isUILocked];
		
		if (locked){ // locked, use SBLockScreenNotificationListController/SBAwayBulletinListController
			
			if (objc_getClass("SBAwayBulletinListController")!=nil){  //older iOSes
			
				SBAwayBulletinListController *listController=[[[objc_getClass("SBAwayController") sharedAwayController ] awayView] valueForKey:@"bulletinController"];
				BBObserver *observer=[listController valueForKey:@"observer"];
				if (attachmentImage){
					//[observer _setAttachmentImage:attachmentImage forKey:@"kBBObserverBulletinAttachmentDefaultKey" forBulletinID:[request bulletinID]];
					[observer _setAttachmentImage:[attachmentImage copy] forKey:@"SBAwayBulletinListAttachmentKey" forBulletinID:[request bulletinID]];
					//[observer _setAttachmentSize:CGSizeMake(60,60) forKey:@"SBAwayBulletinListAttachmentKey" forBulletinID:[request bulletinID]];
				}
				[listController observer:observer addBulletin:request forFeed:8];
				[_cachedLockscreenBulletins addObject:request];

			}
			
			else{ //newer iOSes
			
				SBLockScreenNotificationListController *listController=[[[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
				BBObserver *observer=[listController valueForKey:@"observer"];
		 
				if (attachmentImage){
					//[observer _setAttachmentImage:attachmentImage forKey:@"kBBObserverBulletinAttachmentDefaultKey" forBulletinID:[request bulletinID]];
					[observer _setAttachmentImage:[attachmentImage copy] forKey:@"SBAwayBulletinListAttachmentKey" forBulletinID:[request bulletinID]];
					//[observer _setAttachmentSize:CGSizeMake(60,60) forKey:@"SBAwayBulletinListAttachmentKey" forBulletinID:[request bulletinID]];
				}
			
				if ([objc_getClass("SBLockScreenNotificationListController") instancesRespondToSelector:@selector(observer:addBulletin:forFeed:playLightsAndSirens:withReply:)]){

					[listController observer:observer addBulletin:request forFeed:8 playLightsAndSirens:1 withReply: NULL];
				}
				else{
					[listController observer:observer addBulletin:request forFeed:8];
				}
				[_cachedLockscreenBulletins addObject:request];
				
			}
		}
		else{ //not locked, use SBBulletinBannerController

			BBObserver *observer=[[objc_getClass("SBBulletinBannerController") sharedInstance] valueForKey:@"observer"];
			
			if (attachmentImage){
				
				//UIImage *finalImage=[[objc_getClass("SBBulletinBannerController") sharedInstance] observer:observer composedAttachmentImageForType:1 thumbnailData:UIImagePNGRepresentation(attachmentImage) key:@"kBBObserverBulletinAttachmentDefaultKey"];
				
				[observer _setAttachmentImage:[attachmentImage copy] forKey:@"kBBObserverBulletinAttachmentDefaultKey" forBulletinID:[request bulletinID]];
				if (objc_getClass("SBAwayController")!=nil){
 					
					[_attachmentImagesForIDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:[request bulletinID],@"bulletinID",attachmentImage,@"attachmentImage",NULL]];

				}
			
			}
			
			if ([objc_getClass("SBBulletinBannerController") instancesRespondToSelector:@selector(observer:addBulletin:forFeed:playLightsAndSirens:withReply:)]){
				[[objc_getClass("SBBulletinBannerController") sharedInstance] observer:observer addBulletin:request forFeed:2 playLightsAndSirens: 1 withReply: NULL];
			}
			else{
				
				[[objc_getClass("SBBulletinBannerController") sharedInstance] observer:observer addBulletin:request forFeed:2];
			}
			// no need to remove the bulletin from the observer, SBBulletinBannerController's BBObserver removes it itself upon display
		}

		[attachmentImage release];
		
	});
	
	return request;
}
@end


 

//HOOKS
 
%hook BBBulletinRequest
-(id)composedAttachmentImageForKey:(id)arg1 withObserver:(id)arg2 {

	// for older iOS with SBAwayController

	if ([[self publisherBulletinID] rangeOfString:@"-bulletin-manager"].location==0 && objc_getClass("SBAwayController")!=nil && ![[objc_getClass("SBAwayController") sharedAwayController] isLocked]){
	 
	 	for (NSDictionary *dict in [[JBBulletinManager sharedInstance] attachmentImagesForIDs]){
			if ([[dict objectForKey:@"bulletinID"] isEqual:[self bulletinID]]){
				[[[JBBulletinManager sharedInstance] attachmentImagesForIDs] removeObject:dict];
				return [dict objectForKey:@"attachmentImage"];
				
			}
		}
	 
	}
	return %orig;
}
-(NSUInteger)messageNumberOfLines{

	// for forching max number of lines to 4
	
	if ([[self publisherBulletinID] rangeOfString:@"-bulletin-manager"].location==0){
		return 4;
	}
	
	return %orig;
}
-(UIImage *)sectionIconImageWithFormat:(int)aformat{

	//for forcing custom bundle images	
	
	if ([[self publisherBulletinID] rangeOfString:@"-bulletin-manager"].location==0){
	
		UIImage *customImage=NULL;

		for (NSDictionary *dict in [[JBBulletinManager sharedInstance] bundleImagesForIDs]){
			if ([[dict objectForKey:@"bulletinID"] isEqual:[self bulletinID]]){
				customImage=[dict objectForKey:@"overrideBundleImage"];
			}
		}
		
		if (customImage){

			if (objc_getClass("SBAwayController")!=nil){
				CGFloat height=customImage.size.height;
				CGFloat width=customImage.size.width;
				if (width>20 || height>20){
					CGFloat maxValue=MAX(width,height);
					CGFloat proportion=20/maxValue;
					customImage=[customImage _imageScaledToProportion:proportion interpolationQuality:5];
				}

			}
			return customImage;
		}
	}
	
	return %orig;
}
%end





static void screenChanged() {
	
	// Purge cached lockscreen bulletins like SBLockScreenNotificationListController does upon unlock
	
	static int screenChangedToken=0;
	static BOOL isRemoving=NO;

	if (!screenChangedToken){
		notify_register_check("com.apple.springboard.screenchanged",&screenChangedToken);
	}
	
	uint64_t state;
	notify_get_state(screenChangedToken, &state);
	
	if (((int)state==2 || (int)state==3) && !isRemoving){
		
		isRemoving=YES;

		[[[JBBulletinManager sharedInstance] bundleImagesForIDs] removeAllObjects];
		
		SBLockScreenNotificationListController *lockScreenNotificationListController=[[[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
		
		for (int i=0; i< [[[JBBulletinManager sharedInstance] cachedLockscreenBulletins] count]; i++){
			BBBulletin *bulletin=[[[JBBulletinManager sharedInstance] cachedLockscreenBulletins] objectAtIndex:i];
			BBObserver *observer=[lockScreenNotificationListController valueForKey:@"observer"];
			[[[JBBulletinManager sharedInstance] cachedLockscreenBulletins] removeObject:bulletin];
			[lockScreenNotificationListController observer:observer removeBulletin:bulletin];
			i--;
		}

		isRemoving=NO;
		
	}
}

%ctor{

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&screenChanged, CFSTR("com.apple.springboard.screenchanged"), NULL, 0);
}
