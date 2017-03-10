#import "JBBulletinManager.h"
#import "JBBulletinManager+Private.h"

#include <AudioToolbox/AudioToolbox.h>
#include <objc/runtime.h>
#include <notify.h>

static void screenChanged() {
	// Purge cached lockscreen bulletins like SBLockScreenNotificationListController does upon unlock
	static int screenChangedToken = 0;
	static BOOL isRemoving = NO;
	if (!screenChangedToken) {
		notify_register_check("com.apple.springboard.screenchanged", &screenChangedToken);
	}
	uint64_t state;
	notify_get_state(screenChangedToken, &state);
	if (((int)state == 2 || (int)state == 3) && !isRemoving) {
		isRemoving = YES;
		[[JBBulletinManager sharedInstance] removeAllBulletins];
		isRemoving = NO;
	}
}

@implementation JBBulletinManager

+ (void)load {
	[self sharedInstance];
}

+ (instancetype)sharedInstance {
	static id _sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		_sharedInstance = [self new];
	});
	return _sharedInstance;
}

- (id)init {
	if (self = [super init]) {
		if (objc_getClass("SBAwayController") != nil || (kCFCoreFoundationVersionNumber > 1300)) {
			_attachmentImagesForIDs = [[NSMutableArray alloc] init];
		}
		_bundleImagesForIDs			= [[NSMutableArray alloc] init];
		_cachedLockscreenBulletins 	= [[NSMutableArray alloc] init];

		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&screenChanged, CFSTR("com.apple.springboard.screenchanged"), NULL, 0);
	}
	return self;
}

- (SBLockScreenNotificationListController *)notificationController {
	UIApplication * uiapp = [UIApplication sharedApplication];
	SBLockScreenNotificationListController * controller = ([uiapp respondsToSelector:@selector(notificationDispatcher)] && [[uiapp notificationDispatcher] respondsToSelector:@selector(notificationSource)]) ? [[uiapp notificationDispatcher] notificationSource] : [[[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
	return controller;
}

- (BOOL)isUILocked {
	return [[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] isUILocked];
}

- (NSString *)newUUID {
	CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
	NSString * uuidStr = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject);
	CFRelease(uuidObject);
	return uuidStr;
}

- (BOOL)isiOS10 {
	return kCFCoreFoundationVersionNumber > 1300;
}

- (id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage bundleID:(NSString *)inBundleID {
	// This displays a title and message and the bundleID's image
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:inBundleID hasSound:NO soundID:0 vibrateMode:0 soundPath:NULL attachmentImage:NULL overrideBundleImage:NULL];
}

- (id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage overrideBundleImage:(UIImage *)inOverridBundleImage {
	// This displays a title and message and the overrides the bundleID's expected image with the bundleImage supplied
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:NULL hasSound:NO soundID:0 vibrateMode:0 soundPath:NULL attachmentImage:NULL overrideBundleImage:inOverridBundleImage];
}

- (id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage bundleID:(NSString *)inBundleID soundPath:(NSString *)inSoundPath {
	// This displays a title and message and the bundleID's image and plays a sound from file
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:inBundleID hasSound:YES soundID:0 vibrateMode:0 soundPath:inSoundPath attachmentImage:NULL overrideBundleImage:NULL];
}

- (id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage bundleID:(NSString *)inBundleID soundID:(NSUInteger)inSoundID {
	// This displays a title and message and the bundleID's image and plays a sound from a SystemSoundID
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:inBundleID hasSound:YES soundID:inSoundID vibrateMode:0 soundPath:NULL attachmentImage:NULL overrideBundleImage:NULL];
}

- (id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage overrideBundleImage:(UIImage *)inOverridBundleImage soundPath:(NSString *)inSoundPath {
	// This displays a title and message and the overrides the bundleID's expected image with the bundleImage supplied and plays a sound from file
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:NULL hasSound:YES soundID:0 vibrateMode:0 soundPath:inSoundPath attachmentImage:NULL overrideBundleImage:inOverridBundleImage];
}

- (id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage overrideBundleImage:(UIImage *)inOverridBundleImage soundID:(NSUInteger)inSoundID {
	// This displays a title and message and the overrides the bundleID's expected image with the bundleImage supplied and plays a sound from a SystemSoundID
	return [self showBulletinWithTitle:inTitle message:inMessage bundleID:NULL hasSound:YES soundID:inSoundID vibrateMode:0 soundPath:NULL attachmentImage:NULL overrideBundleImage:inOverridBundleImage];
}

- (id)showBulletinWithTitle:(NSString *)inTitle message:(NSString *)inMessage bundleID:(NSString *)inBundleID hasSound:(BOOL)hasSound soundID:(NSUInteger)soundID vibrateMode:(NSUInteger)vibrate soundPath:(NSString *)inSoundPath attachmentImage:(UIImage *)inAttachmentImage overrideBundleImage:(UIImage *)inOverrideBundleImage {
	__block NSString * title = [inTitle retain];
	__block NSString * message = [inMessage retain];
	__block NSString * soundPath = [inSoundPath retain];
	__block NSString * bundleID = [inBundleID retain];
	__block UIImage * attachmentImage = [inAttachmentImage retain];
	__block UIImage * overrideBundleImage = [inOverrideBundleImage retain];
	__block BBBulletinRequest * request = [[objc_getClass("BBBulletinRequest") alloc] init]; //init here so we can return it

	dispatch_async(dispatch_get_main_queue(), ^ {
		request.section = bundleID;
		request.sectionID = bundleID;
		request.bulletinID = [self newUUID];
		request.bulletinVersionID = [self newUUID];
		request.recordID = [self newUUID];
		request.publisherBulletinID = [NSString stringWithFormat:@"-bulletin-manager-%@", [self newUUID]];
		request.title = title;
		request.message = message;
		request.date = [NSDate date];
		request.lastInterruptDate = [NSDate date];
		[request setClearable:YES];

		if ([request respondsToSelector:@selector(setCategoryID:)]) {
			[request performSelector:@selector(setCategoryID:) withObject:@"CAT_INCOMING_MESSAGE"];
		}
		if (bundleID) {
			BBAction * defaultAction = [objc_getClass("BBAction") actionWithLaunchBundleID:bundleID callblock:nil];
			[request setDefaultAction:defaultAction];
		}
		[title release];
		[message release];
		[bundleID release];

		if (overrideBundleImage) {
			[_bundleImagesForIDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[overrideBundleImage copy], @"overrideBundleImage",
				request.bulletinID, @"bulletinID",
				NULL]
			];
			[overrideBundleImage release];
		}

		if (hasSound) { //behavior is 1 for vibrate , 0 for not (on soundIDS that don't vibrate by default)
			int playID = 1015;
			if (soundID) {
				playID = soundID;
			}
			Class BBSoundClass = objc_getClass("BBSound");
			BBSound * sound = NULL;
			if (soundPath) {
				if ([BBSoundClass instancesRespondToSelector:@selector(initWithSystemSoundPath:behavior:vibrationPattern:)]) {
					sound = [[BBSoundClass alloc] initWithSystemSoundPath:soundPath behavior:0 vibrationPattern:NULL];
				} else {
					CFURLRef fileURL = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)soundPath, kCFURLPOSIXPathStyle, false);
					SystemSoundID outSystemSoundID = 0;
					AudioServicesCreateSystemSoundID(fileURL, &outSystemSoundID);
					if (outSystemSoundID) {
						if ([BBSoundClass instancesRespondToSelector:@selector(initWithSystemSoundID:behavior:vibrationPattern:)]) {
							sound = [[BBSoundClass alloc] initWithSystemSoundID:outSystemSoundID behavior:vibrate vibrationPattern: NULL];
						} else {
							TLAlertConfiguration * conf = [(TLAlertConfiguration *)[objc_getClass("TLAlertConfiguration") alloc] initWithType:17];
							[conf setExternalToneFileURL:[NSURL fileURLWithPath:soundPath]];
							sound = [[BBSoundClass alloc] initWithToneAlertConfiguration:conf];
						}
					}
					AudioServicesDisposeSystemSoundID(outSystemSoundID);
				}
				[soundPath release];
			} else {
				if ([BBSoundClass instancesRespondToSelector:@selector(initWithSystemSoundID:behavior:vibrationPattern:)]) {
					sound = [[BBSoundClass alloc] initWithSystemSoundID:playID behavior:vibrate vibrationPattern: NULL];
				} else {
					sound = [[BBSoundClass alloc] init];
					[sound setSoundType:0];
					[sound setSystemSoundID:playID];
				}
			}
			[request setSound:sound];
		}

		Class SBAwayControllerClass = objc_getClass("SBAwayController");
		if (attachmentImage) {
			// resize attachment to a displayable size of (60,60) for new iOS or (38,38) for older
			if (SBAwayControllerClass != nil) {
				CGFloat height = attachmentImage.size.height;
				CGFloat width = attachmentImage.size.width;
				if (width > 38 || height > 38) {
					CGFloat maxValue = MAX(width, height);
					CGFloat proportion = 38 / maxValue;
					attachmentImage = [attachmentImage _imageScaledToProportion:proportion interpolationQuality:5];
				}
			} else {
				attachmentImage = [attachmentImage imageResizedTo:CGSizeMake(60, 60) preserveAspectRatio: YES];
			}
			[attachmentImage retain];
			if (![self isiOS10]) {
				BBAttachments * atts = [[objc_getClass("BBAttachments") alloc] init];
				[atts setPrimaryType:1];
				request.attachments = atts;
			}
		}
		BOOL locked = (SBAwayControllerClass != nil) ? [[SBAwayControllerClass sharedAwayController] isLocked] : [[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] isUILocked];
		if (locked) { // locked, use SBLockScreenNotificationListController/SBAwayBulletinListController
			if (objc_getClass("SBAwayBulletinListController") != nil) {  //older iOSes
				SBAwayBulletinListController * listController = [[[SBAwayControllerClass sharedAwayController] awayView] valueForKey:@"bulletinController"];
				BBObserver * observer = [listController valueForKey:@"observer"];
				if (attachmentImage) {
					[observer _setAttachmentImage:[attachmentImage copy] forKey:@"SBAwayBulletinListAttachmentKey" forBulletinID:request.bulletinID];
				}
				[listController observer:observer addBulletin:request forFeed:8];
				[_cachedLockscreenBulletins addObject:request];
			} else { //newer iOSes
				SBLockScreenNotificationListController * listController = [self notificationController];
				BBObserver * observer = [listController valueForKey:@"observer"];
				if (attachmentImage) {
					if ([observer respondsToSelector:@selector(_setAttachmentImage:forKey:forBulletinID:)]) {
						[observer _setAttachmentImage:[attachmentImage copy] forKey:@"SBAwayBulletinListAttachmentKey" forBulletinID:request.bulletinID];
					} else {
						// handle iOS 10 Case, store images for later hook
						[_attachmentImagesForIDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							request.bulletinID, @"bulletinID",
							attachmentImage, @"attachmentImage",
							NULL]
						];
					}
				}
				if ([objc_getClass("SBLockScreenNotificationListController") instancesRespondToSelector:@selector(observer:addBulletin:forFeed:playLightsAndSirens:withReply:)]) {
					[listController observer:observer addBulletin:request forFeed:[self isiOS10] ? 27 : 8 playLightsAndSirens:1 withReply: NULL];
				} else {
					[listController observer:observer addBulletin:request forFeed:[self isiOS10] ? 27 : 8];
				}
				[_cachedLockscreenBulletins addObject:request];
			}
		} else { //not locked, use SBBulletinBannerController
			if ([self isiOS10]) {
				SBLockScreenNotificationListController * listController = [self notificationController];
				BBObserver * observer = [listController valueForKey:@"observer"];
				if (attachmentImage) {
					[_attachmentImagesForIDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:request.bulletinID, @"bulletinID", attachmentImage, @"attachmentImage", NULL]];
				}
				if ([objc_getClass("SBLockScreenNotificationListController") instancesRespondToSelector:@selector(observer:addBulletin:forFeed:playLightsAndSirens:withReply:)]) {
					[listController observer:observer addBulletin:request forFeed:27 playLightsAndSirens:1 withReply: NULL];
				} else {
					[listController observer:observer addBulletin:request forFeed:27];
				}
				[_cachedLockscreenBulletins addObject:request];
			} else {
				Class SBBulletinBannerControllerClass = objc_getClass("SBBulletinBannerController");
				SBBulletinBannerController * bannerController = [SBBulletinBannerControllerClass sharedInstance];
				BBObserver * observer = [bannerController valueForKey:@"observer"];
				if (attachmentImage) {
					[observer _setAttachmentImage:[attachmentImage copy] forKey:@"kBBObserverBulletinAttachmentDefaultKey" forBulletinID:request.bulletinID];

					if (SBAwayControllerClass) {
						[_attachmentImagesForIDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:request.bulletinID, @"bulletinID", attachmentImage, @"attachmentImage", NULL]];
					}
				}
				if ([SBBulletinBannerControllerClass instancesRespondToSelector:@selector(observer:addBulletin:forFeed:playLightsAndSirens:withReply:)]) {
					[bannerController observer:observer addBulletin:request forFeed:2 playLightsAndSirens: 1 withReply: NULL];
				} else {
					[bannerController observer:observer addBulletin:request forFeed:2];
				}
				// no need to remove the bulletin from the observer, SBBulletinBannerController's BBObserver removes it itself upon display
			}
		}
		[attachmentImage release];
	});
	return request;
}

- (void)removeBulletinFromLockscreen:(id)inBulletin {
	// use the returned instance from -showBulletinWithTitle method
	if (![self isUILocked]) {
		return;
		// removal is handled upon each unlock, so if the device is unlocked, we shoulnt't allow removing bulletins again
	}
	//SBLockScreenNotificationListController * lockScreenNotificationListController = [[[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
	SBLockScreenNotificationListController * lockScreenNotificationListController = [self notificationController];
	BBObserver * observer = [lockScreenNotificationListController valueForKey:@"observer"];
	[_cachedLockscreenBulletins removeObject:inBulletin];
	[lockScreenNotificationListController observer:observer removeBulletin:inBulletin];
}

- (void)updateBulletinAtLockscreen:(id)inBulletin {
	// use the returned instance from -showBulletinWithTitle method
	if (![self isUILocked]) {
		return;
		// you can only update bulletins at lockscreen , change title, message, content etc
	}
	//SBLockScreenNotificationListController * lockScreenNotificationListController = [[[objc_getClass("SBLockScreenManager") sharedInstanceIfExists] lockScreenViewController] valueForKey:@"notificationController"];
	SBLockScreenNotificationListController * lockScreenNotificationListController = [self notificationController];
	BBObserver * observer = [lockScreenNotificationListController valueForKey:@"observer"];
	if ([lockScreenNotificationListController respondsToSelector:@selector(observer:modifyBulletin:)]) {
		[lockScreenNotificationListController observer:observer modifyBulletin:inBulletin];
	} else  { //iOS10
		[lockScreenNotificationListController observer:observer modifyBulletin:inBulletin forFeed:8];
	}
}

- (UIImage *)customImageForBulletinRequest:(BBBulletinRequest *)bulletinRequest {
	UIImage * customImage = nil;
	for (NSDictionary * dict in [self bundleImagesForIDs]) {
		if ([[dict objectForKey:@"bulletinID"] isEqual:bulletinRequest.bulletinID]) {
			customImage = [dict objectForKey:@"overrideBundleImage"];
			break;
		}
	}
	if (customImage) {
		if (objc_getClass("SBAwayController") != nil) {
			CGFloat height = customImage.size.height;
			CGFloat width = customImage.size.width;
			if (width > 20 || height > 20) {
				CGFloat maxValue = MAX(width, height);
				CGFloat proportion = 20 / maxValue;
				customImage = [customImage _imageScaledToProportion:proportion interpolationQuality:(CGInterpolationQuality)5];
			}
		}
	}
	return customImage;
}

- (id)popImageForBulletinRequest:(BBBulletinRequest *)bulletinRequest {
	if ([bulletinRequest.publisherBulletinID rangeOfString:@"-bulletin-manager"].location == 0) {
		for (NSDictionary * dict in _attachmentImagesForIDs) {
			if ([[dict objectForKey:@"bulletinID"] isEqual:bulletinRequest.bulletinID]) {
				[_attachmentImagesForIDs removeObject:dict];
				return [dict objectForKey:@"attachmentImage"];
			}
		}
	}
	return nil;
}

- (void)removeAllBulletins {
	SBLockScreenNotificationListController * lockScreenNotificationListController = [self notificationController];
	BBObserver * observer = [lockScreenNotificationListController valueForKey:@"observer"];
	for (BBBulletin * bulletin in [self cachedLockscreenBulletins]) {
		[lockScreenNotificationListController observer:observer removeBulletin:bulletin];
	}
	[[self cachedLockscreenBulletins] removeAllObjects];
	[[self bundleImagesForIDs] removeAllObjects];
}

@end
