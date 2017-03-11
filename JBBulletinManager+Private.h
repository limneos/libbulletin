#import "imports.h"
#import "JBBulletinManager.h"

@interface JBBulletinManager ()

@property (retain) NSMutableArray * attachmentImagesForIDs;
@property (retain) NSMutableArray * bundleImagesForIDs;
@property (retain) NSMutableArray * cachedLockscreenBulletins;

- (BOOL)isUILocked;
- (NSString *)newUUID;

- (SBLockScreenNotificationListController *)notificationController;

- (UIImage *)customImageForBulletinRequest:(BBBulletinRequest *)bulletinRequest;
- (id)popImageForBulletinRequest:(BBBulletinRequest *)bulletinRequest;
- (void)removeAllBulletins;

@end
