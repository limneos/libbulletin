/*
feeds:
1 = NC
2 = BANNER
4 = MODAL ALERT
8 = LOCKSCREEN
16 = SOUND
128 = CAR

*/


#include "imports.h"
#include "JBBulletinManager.h"
#include <mach-o/dyld.h>

@interface SBLockScreenUnlockRequest : NSObject
-(void)setDestinationApplication:(id)arg1;
-(void)setWantsBiometricPresentation:(BOOL)arg1;
-(BOOL)wantsBiometricPresentation;
-(void)setProcess:(id)arg1;
-(void)setName:(NSString *)arg1;
-(void)setSource:(int)arg1;
-(void)setIntent:(int)arg1;
@end

void mylog(const char *sdf){
	
	static const char mon_name[][4] = {
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    };
    char timestr[256];
    
    time_t rawtime;
    struct tm * timeptr;

    time ( &rawtime );
    timeptr = localtime ( &rawtime );
                
	FILE *p=fopen("/tmp/syslog","a");

	if (p){

		sprintf(timestr, "%.3s %d %.2d:%.2d:%.2d %s[%d]",

            mon_name[timeptr->tm_mon],
            timeptr->tm_mday, timeptr->tm_hour,
            timeptr->tm_min, timeptr->tm_sec,getprogname(),getpid());
    
		char logtxt[strlen(sdf)+strlen(timestr)+4];
		sprintf(logtxt,"%s %s\n",timestr,sdf);
		fwrite(logtxt,strlen(logtxt),1,p);
		fclose(p);
	}

}

#define NSLog(...) mylog([[NSString stringWithFormat:__VA_ARGS__] UTF8String])

static BOOL IOS10=NO;
static BOOL IOS11=NO;

@implementation JBBulletinManager{

	NSMutableArray *_attachmentImagesForIDs;
	NSMutableArray *_bundleImagesForIDs;
	NSMutableArray *_cachedLockscreenBulletins;
	int _nextBulletinDestination;

}

static JBBulletinManager *sharedJB=NULL;
 
+(id)sharedInstance{

	if (!sharedJB){
		
		sharedJB = [[self alloc] init];
		
	}
	return sharedJB;

}
-(id)notificationController{
	
	SBLockScreenNotificationListController *lockScreenNotificationListController=([[objc_getClass("UIApplication") sharedApplication] respondsToSelector:@selector(notificationDispatcher)] && [[[objc_getClass("UIApplication") sharedApplication] notificationDispatcher] respondsToSelector:@selector(notificationSource)]) ? [[[objc_getClass("UIApplication") sharedApplication] notificationDispatcher] notificationSource]  : [[[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
	return lockScreenNotificationListController;

}
-(id)init{
	
	if (self=[super init]){

		if (objc_getClass("SBAwayController")!=nil || IOS10){
			_attachmentImagesForIDs = [[NSMutableArray alloc] init];
		}
		_bundleImagesForIDs			= [[NSMutableArray alloc] init];
		_cachedLockscreenBulletins 	= [[NSMutableArray alloc] init];
		_nextBulletinDestination=0;
		sharedJB=self;
	}
	return self;

}

-(void)setNextBulletinDestination:(int)destination{
	_nextBulletinDestination=destination;
}
-(int)nextBulletinDestination{
	return _nextBulletinDestination;
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

-(id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage overrideBundleImage:(UIImage *)inOverridBundleImage soundID:(int)inSoundID{

	// This displays a title and message and the overrides the bundleID's expected image with the bundleImage supplied and plays a sound from a SystemSoundID
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:NULL hasSound:YES soundID:inSoundID vibrateMode:0 soundPath:NULL attachmentImage:NULL overrideBundleImage:inOverridBundleImage];
}
-(id)bulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage bundleID:(NSString *)inBundleID{
	
	__block NSString *title=[inTitle retain];
	__block NSString *message=[inMessage retain];
	__block NSString *bundleID=inBundleID ? [inBundleID retain] : [@"com.something.anything" retain];

	 
	BBBulletin *request=[[objc_getClass("BBBulletin") alloc] init]; //init here so we can return it
	
	
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



	if ([request respondsToSelector:@selector(setCategoryID:)]){
		[request performSelector:@selector(setCategoryID:) withObject:IOS10 ? @"libbulletin" : @"CAT_INCOMING_MESSAGE"];
	}
	
	
	if (bundleID){
		BBAction *defaultAction = [objc_getClass("BBAction") actionWithLaunchBundleID:bundleID callblock:nil];
		[request setDefaultAction:defaultAction];
	}
	 
	
	[title release];
	[message release];
	[bundleID release];
	return request;

}

-(id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage bundleID:(NSString *)inBundleID hasSound:(BOOL)hasSound soundID:(int)soundID vibrateMode:(int)vibrate soundPath:(NSString *)inSoundPath attachmentImage:(UIImage *)inAttachmentImage overrideBundleImage:(UIImage *)inOverrideBundleImage{
	
	__block NSString *title=[inTitle retain];
	__block NSString *message=[inMessage retain];
	__block NSString *soundPath=[inSoundPath retain];
	__block NSString *bundleID=inBundleID ? [inBundleID retain] : [@"com.something.anything" retain];
	__block UIImage *attachmentImage=[inAttachmentImage retain];
	__block UIImage *overrideBundleImage=[inOverrideBundleImage retain];

	 
	__block BBBulletinRequest *request=[[objc_getClass("BBBulletin") alloc] init]; //init here so we can return it
	
	
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
 
	

		if ([request respondsToSelector:@selector(setCategoryID:)]){
			[request performSelector:@selector(setCategoryID:) withObject:IOS10 ? @"libbulletin" : @"CAT_INCOMING_MESSAGE"];
		}
		
		
		if (bundleID){
			if (IOS11){
				BBAction *defaultAction = [objc_getClass("BBAction") actionWithIdentifier:@"com.apple.UNNotificationDefaultActionIdentifier"];
				
				[defaultAction setIdentifier:@"com.apple.UNNotificationDefaultActionIdentifier"];
				[request setDefaultAction:defaultAction];
				[defaultAction  setActionType:1];
				[defaultAction  setLaunchURL:NULL];
				[defaultAction  setLaunchBundleID:NULL];
				[defaultAction  setLaunchCanBypassPinLock:0];
				[defaultAction  setActivatePluginName:NULL];
				[defaultAction  setActivatePluginContext:NULL];
				[defaultAction  setRemoteViewControllerClassName:NULL];
				[defaultAction  setRemoteServiceBundleIdentifier:NULL];
				[defaultAction  setActivationMode:0];
				[defaultAction  setBehavior:0];
				[defaultAction  setBehaviorParameters:NULL];
				[defaultAction  setAuthenticationRequired:0];
				[defaultAction  setShouldDismissBulletin:1];

			}
			else if (IOS10){
				BBAction *defaultAction = [objc_getClass("BBAction") actionWithLaunchBundleID:bundleID callblock:^{}];
				[request setDefaultAction:defaultAction];

			}
			else{
				BBAction *defaultAction = [objc_getClass("BBAction") actionWithLaunchBundleID:bundleID callblock:^{}];
				[request setDefaultAction:defaultAction];
			}
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
						if ([objc_getClass("BBSound") instancesRespondToSelector:@selector(initWithSystemSoundID:behavior:vibrationPattern:)]){
							sound=[[objc_getClass("BBSound") alloc] initWithSystemSoundID:outSystemSoundID behavior:vibrate vibrationPattern: NULL];
						}
						else{
							TLAlertConfiguration *conf=[(TLAlertConfiguration*)[objc_getClass("TLAlertConfiguration") alloc] initWithType:17];
							[conf setExternalToneFileURL:[NSURL fileURLWithPath:soundPath]];
							sound=[[objc_getClass("BBSound") alloc] initWithToneAlertConfiguration:conf];
						}
					}
					AudioServicesDisposeSystemSoundID(outSystemSoundID);
				}
				[soundPath release];
			}
			else{
				if ([objc_getClass("BBSound") instancesRespondToSelector:@selector(initWithSystemSoundID:behavior:vibrationPattern:)]){
					sound=[[objc_getClass("BBSound") alloc] initWithSystemSoundID:playID behavior:vibrate vibrationPattern: NULL];						
				}
				else{
					if (IOS11){
						[[UIDevice currentDevice] _playSystemSound:playID];
					}
					else{
						sound=[[objc_getClass("BBSound") alloc] init];
						[sound setSoundType:0];
						[sound setSystemSoundID:playID];
					}
				}

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
			if (IOS11){
				BBAttachments *atts=[[objc_getClass("BBAttachments") alloc] init];
				[atts setPrimaryType:1];
				request.attachments=atts;
			}
			 
		}
		 
		 
		 
		BOOL locked = objc_getClass("SBAwayController")!=nil ? [[objc_getClass("SBAwayController") sharedAwayController] isLocked] : [[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] isUILocked];
		
		if (locked){ // locked, use SBLockScreenNotificationListController/SBAwayBulletinListController
		
			if (objc_getClass("SBAwayBulletinListController")!=nil){  //older iOSes
		
				SBAwayBulletinListController *listController=[[[objc_getClass("SBAwayController") sharedAwayController ] awayView] valueForKey:@"bulletinController"];
				BBObserver *observer=[listController valueForKey:@"observer"];
				if (attachmentImage){

					[observer _setAttachmentImage:[attachmentImage copy] forKey:@"SBAwayBulletinListAttachmentKey" forBulletinID:[request bulletinID]];

				}
				[listController observer:observer addBulletin:request forFeed:8];
				[_cachedLockscreenBulletins addObject:request];

			}
		
			else{ //newer iOSes
		
				SBLockScreenNotificationListController *listController=[self notificationController];
				BBObserver *observer=[listController valueForKey:@"observer"];
			
				if (attachmentImage){
				
					if ([observer respondsToSelector:@selector(_setAttachmentImage:forKey:forBulletinID:)]){
						[observer _setAttachmentImage:[attachmentImage copy] forKey:@"SBAwayBulletinListAttachmentKey" forBulletinID:[request bulletinID]];
					}
					else{
						// handle iOS 10 Case, store images for later hook
						[_attachmentImagesForIDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:[request bulletinID],@"bulletinID",attachmentImage,@"attachmentImage",NULL]];
					}	
				 
				}
		
				if ([objc_getClass("SBLockScreenNotificationListController") instancesRespondToSelector:@selector(observer:addBulletin:forFeed:playLightsAndSirens:withReply:)]){

					[listController observer:observer addBulletin:request forFeed:_nextBulletinDestination == 0 ? 8|16  : _nextBulletinDestination playLightsAndSirens:YES withReply: NULL];
				
				}
				else{
			
					[listController observer:observer addBulletin:request forFeed:IOS10 ? (_nextBulletinDestination == 0 ? 27|16 : _nextBulletinDestination) : 8];
				
				}
			
				[_cachedLockscreenBulletins addObject:request];
			
			}
		}
		else{ //not locked, use SBBulletinBannerController
		
			if (IOS10){
		
				SBLockScreenNotificationListController *listController=[self notificationController];
				BBObserver *observer=[listController valueForKey:@"observer"];
			
				if (attachmentImage){

					[_attachmentImagesForIDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:[request bulletinID],@"bulletinID",attachmentImage,@"attachmentImage",NULL]];

				}
		
				if ([objc_getClass("SBLockScreenNotificationListController") instancesRespondToSelector:@selector(observer:addBulletin:forFeed:playLightsAndSirens:withReply:)]){

						[listController observer:observer addBulletin:request forFeed:IOS10 ? (_nextBulletinDestination == 0 ? 27|16 : _nextBulletinDestination) : 8 playLightsAndSirens:YES withReply: NULL];

				
				}
				else{

					[listController observer:observer addBulletin:request forFeed:IOS10 ? (_nextBulletinDestination == 0 ? 27|16 : _nextBulletinDestination) : 8];
				
				}
			
				[_cachedLockscreenBulletins addObject:request];
 
			}
			else{
		
				BBObserver *observer=[[objc_getClass("SBBulletinBannerController") sharedInstance] valueForKey:@"observer"];
		
				if (attachmentImage){
			
				
					[observer _setAttachmentImage:[attachmentImage copy] forKey:@"kBBObserverBulletinAttachmentDefaultKey" forBulletinID:[request bulletinID]];
				
					if (objc_getClass("SBAwayController")!=nil){
				
						[_attachmentImagesForIDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:[request bulletinID],@"bulletinID",attachmentImage,@"attachmentImage",NULL]];

					}
		
				}
		
				if ([objc_getClass("SBBulletinBannerController") instancesRespondToSelector:@selector(observer:addBulletin:forFeed:playLightsAndSirens:withReply:)]){

						[[objc_getClass("SBBulletinBannerController") sharedInstance] observer:observer addBulletin:request forFeed:2 playLightsAndSirens:YES withReply: NULL];

				}
				else{

					[[objc_getClass("SBBulletinBannerController") sharedInstance] observer:observer addBulletin:request forFeed:2];

				}
				// no need to remove the bulletin from the observer, SBBulletinBannerController's BBObserver removes it itself upon display
			}
		}

		[attachmentImage release];
		 
		_nextBulletinDestination=0;
	});
	
	return request;
}
 
-(void)removeBulletinFromLockscreen:(id)inBulletin{
	
	// use the returned instance from -showBulletinWithTitle method 
	if (![[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] isUILocked]){
		return;
		// removal is handled upon each unlock, so if the device is unlocked, we shoulnt't allow removing bulletins again
	}
	//SBLockScreenNotificationListController *lockScreenNotificationListController=[[[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
	SBLockScreenNotificationListController *lockScreenNotificationListController=[self notificationController];
	BBObserver *observer=[lockScreenNotificationListController valueForKey:@"observer"];
	[[self cachedLockscreenBulletins] removeObject:inBulletin];
	[lockScreenNotificationListController observer:observer removeBulletin:inBulletin];
	
}
-(void)updateBulletinAtLockscreen:(id)inBulletin{

	// use the returned instance from -showBulletinWithTitle method 	
	if (![[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] isUILocked]){
		return;
		// you can only update bulletins at lockscreen , change title, message, content etc
	}
	//SBLockScreenNotificationListController *lockScreenNotificationListController=[[[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
	SBLockScreenNotificationListController *lockScreenNotificationListController=[self notificationController];
	BBObserver *observer=[lockScreenNotificationListController valueForKey:@"observer"];
	if ([lockScreenNotificationListController respondsToSelector:@selector(observer:modifyBulletin:)]){
		[lockScreenNotificationListController observer:observer modifyBulletin:inBulletin];
	}
	else  { //iOS10
		[lockScreenNotificationListController observer:observer modifyBulletin:inBulletin forFeed:8] ;
	}

}
-(void)updateBulletinAtNotificationCenter:(id)inBulletin{

	// use the returned instance from -showBulletinWithTitle method 	
	if (![[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] isUILocked]){
		return;
		// you can only update bulletins at lockscreen , change title, message, content etc
	}
	//SBLockScreenNotificationListController *lockScreenNotificationListController=[[[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
	SBLockScreenNotificationListController *lockScreenNotificationListController=[self notificationController];
	BBObserver *observer=[lockScreenNotificationListController valueForKey:@"observer"];
	if ([lockScreenNotificationListController respondsToSelector:@selector(observer:modifyBulletin:)]){
		[lockScreenNotificationListController observer:observer modifyBulletin:inBulletin];
	}
	else  { //iOS10
		[lockScreenNotificationListController observer:observer modifyBulletin:inBulletin forFeed:1] ;
	}

}
@end

 

%group bb



%hook BBBulletin
 

-(id)responseForAction:(id)arg1{

	id x= %orig;
	// handle actions for iOS 10 / IOS 11
	if ([[self publisherBulletinID] rangeOfString:@"-bulletin-manager"].location==0 && IOS10 ){
	
	
		if ([arg1 actionType]==8 || [arg1 actionType]==0 ){
			[[objc_getClass("JBBulletinManager") sharedInstance ] removeBulletinFromLockscreen:self];
		}
		if ([arg1 actionType]==1){
		 
			if ([[objc_getClass("SBLockScreenManager") sharedInstance] isUILocked]){
				
				
				SBLockScreenUnlockRequest *request=[[objc_getClass("SBLockScreenUnlockRequest") alloc] init];
				if ([request respondsToSelector:@selector(setSource:)]){
					[request setSource:16];
				}
				else if ([request respondsToSelector:@selector(setIntent:)]){
					[request setIntent:3];
				}
				else if ([request respondsToSelector:@selector(setName:)]){
					[request setName:[NSString stringWithFormat:@"SBWorkspaceRequest: Open \"%@\"",[self section]]];
				}
				else if ([request respondsToSelector:@selector(setProcess:)]){
					[request setProcess:NULL];
				}
				else if ([request respondsToSelector:@selector(setDestinationApplication:)]){
					[request setDestinationApplication:[[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:[self section]]];
				}
				else if ([request respondsToSelector:@selector(setWantsBiometricPresentation:)]){
					[request setWantsBiometricPresentation:YES];
				}
				else if ([[objc_getClass("SBLockScreenManager") sharedInstance] respondsToSelector:@selector(unlockWithRequest:completion:)]){
					[[objc_getClass("SBLockScreenManager") sharedInstance] unlockWithRequest:request completion:^(BOOL completed){
						if (completed){
							[[UIApplication sharedApplication] launchApplicationWithIdentifier:[self section] suspended:NO];
						}
				
					}];
				}
			}
			else{
				[[UIApplication sharedApplication] launchApplicationWithIdentifier:[self section] suspended:NO];
			}

		}
		
	}
	return x;
}
-(id)composedAttachmentImageWithObserver:(id)observer{

	// handle attachments for iOS 10
	if ([[self publisherBulletinID] rangeOfString:@"-bulletin-manager"].location==0 && IOS10 ){
	 	
	 	for (NSDictionary *dict in [[JBBulletinManager sharedInstance] attachmentImagesForIDs]){

			if ([[dict objectForKey:@"bulletinID"] isEqual:[self bulletinID]]){
				[[[JBBulletinManager sharedInstance] attachmentImagesForIDs] removeObject:dict];
				return [dict objectForKey:@"attachmentImage"];

			}
		}
	 
	}
	return %orig;

}
-(id)composedAttachmentImageForKey:(id)arg1 withObserver:(id)arg2 {

	// handle attachments for older iOS with SBAwayController

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

	// for forcing max number of lines to 4
	
	if ([[self publisherBulletinID] rangeOfString:@"-bulletin-manager"].location==0){
		return 4;
	}
	
	return %orig;
}
-(UIImage *)sectionIconImageWithFormat:(int)aformat{
	 
	//for forcing custom bundle (icon) images	
	
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
-(BBSectionIcon *)sectionIcon{
 
	//for forcing custom bundle (icon) images on iOS 10
	
	if (IOS11){
		return %orig;
	}

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
		
			BBSectionIconVariant *variant = [[objc_getClass("BBSectionIconVariant") alloc] init];
			[variant setImageData:UIImagePNGRepresentation(customImage)];
			BBSectionIcon *icon=[[objc_getClass("BBSectionIcon") alloc] init];
			[icon addVariant:variant];
			
			return icon;
		}
	}
	
	return %orig;
}
%end
%end

%group ios10
%hook NCNotificationLongLookViewController
-(void)_handleCloseButton:(id)arg1{

	%orig;
	if ([self respondsToSelector:@selector(notificationRequest)] && [[self notificationRequest] respondsToSelector:@selector(bulletin)]){

		if ([[[[self notificationRequest] bulletin] publisherBulletinID] rangeOfString:@"-bulletin-manager"].location!=NSNotFound){
			[[objc_getClass("JBBulletinManager") sharedInstance ] removeBulletinFromLockscreen:[[self notificationRequest] bulletin]];
		}
		
	}
}
%end


%hook NCNotificationPriorityListViewController
 
-(void)notificationListCell:(id)arg1 requestsClearingNotificationRequest:(NCNotificationRequest *)arg2 {

	%orig;
	if ([arg2 respondsToSelector:@selector(bulletin)]){
		if ([[[arg2 bulletin] publisherBulletinID] rangeOfString:@"-bulletin-manager"].location!=NSNotFound){
			[[objc_getClass("JBBulletinManager") sharedInstance ] removeBulletinFromLockscreen:[arg2 bulletin]];
		}
	}
}
 
-(void)notificationListCell:(id)arg1 requestsPerformAction:(id)arg2 forNotificationRequest:(NCNotificationRequest *)arg3 completion:(/*^block*/id)arg4{
	 
	%orig;
	if ([arg3 respondsToSelector:@selector(bulletin)]){
		if ([[[arg3 bulletin] publisherBulletinID] rangeOfString:@"-bulletin-manager"].location!=NSNotFound){
			[[objc_getClass("JBBulletinManager") sharedInstance ] removeBulletinFromLockscreen:[arg3 bulletin]];
		}
	}
}
%end
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
		
		SBLockScreenNotificationListController *lockScreenNotificationListController=[[JBBulletinManager sharedInstance] notificationController];
		
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



static void func(const struct mach_header* mh, intptr_t vmaddr_slide){

	
	static BOOL hasRegBB=NO;
	if (objc_getClass("BBBulletin")!=nil && !hasRegBB){
		hasRegBB=1;
		%init(bb);
	}

	
}


%ctor{
	%init;
	IOS10=[[[NSProcessInfo processInfo] operatingSystemVersionString ] rangeOfString:@"Version 10."].location!=NSNotFound || [[[NSProcessInfo processInfo] operatingSystemVersionString ] rangeOfString:@"Version 11."].location!=NSNotFound || [[[NSProcessInfo processInfo] operatingSystemVersionString ] rangeOfString:@"Version 12."].location!=NSNotFound;
	IOS11=[[[NSProcessInfo processInfo] operatingSystemVersionString ] rangeOfString:@"Version 11."].location!=NSNotFound || [[[NSProcessInfo processInfo] operatingSystemVersionString ] rangeOfString:@"Version 12."].location!=NSNotFound;
	if (IOS10){
		%init(ios10);
	}
	_dyld_register_func_for_add_image(func);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&screenChanged, CFSTR("com.apple.springboard.screenchanged"), NULL, 0);
}
