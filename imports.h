#import <UIKit/UIKit.h>

#pragma mark - UIKit

@class SBNCNotificationDispatcher;

@interface UIApplication (ios10additions)
- (SBNCNotificationDispatcher *)notificationDispatcher;
@end

@interface UIImage ()
+ (id)imageNamed:(NSString *)named inBundle:(NSBundle *)bundle;
- (id)imageScaledToSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius;
- (id)_imageScaledToProportion:(CGFloat)proportion interpolationQuality:(CGInterpolationQuality)quality;
- (id)imageResizedTo:(CGSize)size preserveAspectRatio:(BOOL)preserve;
@end

#pragma mark - ToneLibrary.framework

@interface TLAlertConfiguration : NSObject
- (id)initWithType:(NSInteger)type;
- (void)setExternalToneFileURL:(NSURL *)aURL;
@end

#pragma mark - BulletinBoard.framework

@interface BBSectionIconVariant : NSObject
- (void)setImageData:(NSData *)data;
@end

@interface BBSectionIcon : NSObject
- (void)addVariant:(BBSectionIconVariant *)variant;
@end

@protocol BBObserverDelegate <NSObject>
- (void)observer:(id)arg1 addBulletin:(id)bulletin forFeed:(NSUInteger)feed;
- (void)observer:(id)arg1 addBulletin:(id)bulletin forFeed:(NSInteger)feed playLightsAndSirens:(BOOL)playLightsAndSirens withReply:(/*^block*/id)reply;
- (void)observer:(id)arg1 modifyBulletin:(id)bulletin;
- (void)observer:(id)arg1 modifyBulletin:(id)bulletin forFeed:(NSUInteger)feed;
- (void)observer:(id)arg1 removeBulletin:(id)bulletin;
- (void)observer:(id)arg1 removeBulletin:(id)bulletin forFeed:(NSUInteger)feed;
@end

@interface BBObserver: NSObject
- (void)_setAttachmentImage:(id)image forKey:(id)aKey forBulletinID:(NSString *)bulletinID;
- (void)_setAttachmentSize:(CGSize)size forKey:(id)aKey forBulletinID:(NSString *)bulletinID;
@end

@interface BBAction : NSObject
@property (nonatomic,assign) int actionType;
@property (nonatomic,retain) NSURL * launchURL;
+ (id)actionWithCallblock:(id)callblock;
+ (id)actionWithLaunchBundleID:(NSString *)id callblock:(id)aBlock;
+ (id)actionWithLaunchURL:(NSURL *)aURL callblock:(id)aBlock;
@end

@interface BBSound : NSObject
- (id)initWithSystemSoundID:(NSUInteger)systemSoundID behavior:(NSUInteger)behavior vibrationPattern:(id)pattern;
- (id)initWithSystemSoundPath:(id)systemSoundPath behavior:(NSUInteger)behavior vibrationPattern:(id)pattern;
- (id)initWithToneAlert:(NSInteger)toneAlert;
- (id)initWithToneAlertConfiguration:(TLAlertConfiguration *)toneAlertConfiguration;
- (void)setSoundType:(NSInteger)type;
- (void)setSystemSoundID:(NSUInteger)systemSoundID;
@end

@interface BBAttachments : NSObject
- (void)setPrimaryType:(NSInteger)type;
@end

@interface BBAttachmentMetadata
- (id)_initWithUUID:(id)uuid type:(NSInteger)type URL:(NSURL *)aURL;
@end

@interface BBBulletinRequest : NSObject
@property (nonatomic, retain) NSString * bulletinID;
@property (nonatomic, retain) NSString * title;
//@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * sectionID;
@property (nonatomic, retain) NSString * section;
@property (nonatomic, retain) BBSound * sound;
//@property (nonatomic, retain) NSDictionary * context;
//@property (nonatomic, retain) id unlockActionLabel;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDate * lastInterruptDate;
//@property (nonatomic, retain) NSDate * recencyDate;
//@property (nonatomic, retain) NSDate * endDate;
//@property (nonatomic, retain) NSDate * publicationDate;
//@property (nonatomic, assign) BOOL hasEventDate;
@property (nonatomic, assign) BOOL clearable;
//@property (nonatomic, assign) int dateFormatStyle;
//@property (nonatomic, assign) int messageNumberOfLines;
//@property (nonatomic, assign) int sectionSubtype;
@property (nonatomic, retain) BBAction * defaultAction;
//@property (nonatomic, copy)   BBAction * alternateAction;
//@property (nonatomic, copy)   BBAction * acknowledgeAction;
//@property (nonatomic, copy)   BBAction * snoozeAction;
//@property (nonatomic, retain) BBAction * raiseAction;
//@property (nonatomic, assign) BOOL showsMessagePreview;
//@property (nonatomic, assign) BOOL suppressesMessageForPrivacy;
//@property (nonatomic, retain) NSString * unlockActionLabelOverride;
@property (nonatomic, retain) NSString * bulletinVersionID;
//@property (nonatomic, retain) NSTimeZone * timeZone;
//@property (nonatomic, assign) BOOL dateIsAllDay;
@property (nonatomic, retain) BBAttachments * attachments;
@property (nonatomic, retain) NSString * recordID;
@property (nonatomic, retain) NSString * publisherBulletinID;

- (void)setPrimaryAttachment:(BBAttachmentMetadata *)attachmentMetadata;

@end

@interface BBBulletin : BBBulletinRequest
@end

#pragma mark - UserNotificationsUIKit

@interface NCBulletinNotificationSource : NSObject
- (BBObserver *)observer;
@end

#pragma mark - SpringBoard

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
+ (id)sharedInstanceIfExists;
- (BOOL)isUILocked;
- (id)lockScreenViewController;
@end

@interface SBAwayController : NSObject
+ (id)sharedAwayController;
- (BOOL)isLocked;
@end

@interface SBAwayBulletinListController : NSObject <BBObserverDelegate>
+ (id)sharedInstance;
- (id)awayView;
@end

@interface SBBulletinBannerController : NSObject  <BBObserverDelegate>
@end

@interface SBLockScreenNotificationListController : NSObject  <BBObserverDelegate>
@end

@interface SBNCNotificationDispatcher : NSObject
- (NCBulletinNotificationSource *)notificationSource;
@end
