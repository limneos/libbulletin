#import "imports.h"
#import "JBBulletinManager.h"
#import "JBBulletinManager+Private.h"

%hook BBBulletinRequest

- (id)composedAttachmentImageWithObserver:(id)observer {
	// handle attachments for iOS 10
	if (kCFCoreFoundationVersionNumber > 1300) {
		return [[JBBulletinManager sharedInstance] popImageForBulletinRequest:self] ?: %orig;
	}
	return %orig;
}

- (id)composedAttachmentImageForKey:(id)aKey withObserver:(id)observer {
	// handle attachments for older iOS with SBAwayController
	id customImage = nil;
	if (![[objc_getClass("SBAwayController") sharedAwayController] isLocked]) {
		customImage = [[JBBulletinManager sharedInstance] popImageForBulletinRequest:self];
	}
	return customImage ?: %orig;
}

- (NSUInteger)messageNumberOfLines {
	// for forcing max number of lines to 4
	if ([[self publisherBulletinID] rangeOfString:@"-bulletin-manager"].location == 0) {
		return 4;
	}
	return %orig;
}

- (UIImage *)sectionIconImageWithFormat:(int)format {
	//for forcing custom bundle (icon) images
	UIImage * customImage = nil;
	if ([[self publisherBulletinID] rangeOfString:@"-bulletin-manager"].location == 0) {
		customImage = [[JBBulletinManager sharedInstance] customImageForBulletinRequest:self];
	}
	return customImage ?: %orig;
}

- (BBSectionIcon *)sectionIcon {
	//for forcing custom bundle (icon) images on iOS 10
	if (kCFCoreFoundationVersionNumber < 1300) {
		return %orig;
	}
	//for forcing custom bundle images
	if ([[self publisherBulletinID] rangeOfString:@"-bulletin-manager"].location == 0) {
		UIImage * customImage = [[JBBulletinManager sharedInstance] customImageForBulletinRequest:self];
		if (customImage) {
			BBSectionIconVariant * variant = [[objc_getClass("BBSectionIconVariant") alloc] init];
			[variant setImageData:UIImagePNGRepresentation(customImage)];
			BBSectionIcon * icon = [[objc_getClass("BBSectionIcon") alloc] init];
			[icon addVariant:variant];
			return icon;
		}
	}
	return %orig;
}

%end
