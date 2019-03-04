#include <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>
#include "objc/runtime.h"
#include "notify.h"


@interface BBSectionIconVariant : NSObject
-(void)setImageData:(NSData *)data;
@end

@interface BBSectionIcon : NSObject
-(void)addVariant:(id)variant;
@end



@interface UIImage ()
+(id)imageNamed:(id)named inBundle:(id)bundle;
-(id)imageScaledToSize:(CGSize)size cornerRadius:(CGFloat)corenrasd;
-(id)_imageScaledToProportion:(CGFloat)proportion interpolationQuality:(int)quality;
-(id)imageResizedTo:(CGSize)size preserveAspectRatio:(BOOL)preserve;
-(id)sbf_resizeImageToSize:(CGSize)arg1 preservingAspectRatio:(BOOL)arg2 ;
@end


@interface BBAttachmentMetadata
-(id)_initWithUUID:(id)arg1 type:(long long)arg2 URL:(id)arg3 ;
@end


@interface SBAwayController : NSObject
+(id)sharedAwayController;
-(BOOL)isLocked;
@end

@protocol BBObserverDelegate <NSObject>
-(void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(NSInteger)arg3 playLightsAndSirens:(BOOL)arg4 withReply:(/*^block*/id)arg5;
-(void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(NSUInteger)arg3;
-(void)observer:(id)arg1 modifyBulletin:(id)arg2 forFeed:(NSUInteger)arg3;
-(void)observer:(id)arg1 modifyBulletin:(id)arg2;
-(void)observer:(id)arg1 removeBulletin:(id)arg2 forFeed:(NSUInteger)arg3;
-(void)observer:(id)arg1 removeBulletin:(id)arg2;
@end


@interface BBObserver: NSObject
-(void)_setAttachmentImage:(id)image forKey:(id)akwy forBulletinID:(id)bullid;
-(void)_setAttachmentSize:(CGSize)size forKey:(id)akwy forBulletinID:(id)bullid;
@end


@interface NCBulletinNotificationSource : NSObject
-(BBObserver*)observer;
@end

@interface SBNCNotificationDispatcher : NSObject
-(NCBulletinNotificationSource*)notificationSource;
@end


@interface UIApplication (ios10additions)
-(SBNCNotificationDispatcher*)notificationDispatcher;
@end

@interface SBAwayBulletinListController : NSObject <BBObserverDelegate>
+(id)sharedInstance;
-(id)awayView;
@end

@interface SBBulletinBannerController : NSObject  <BBObserverDelegate>
@end

@interface SBLockScreenNotificationListController : NSObject  <BBObserverDelegate>
@end

@interface SBLockScreenManager : NSObject
+(id)sharedInstance;
+(id)sharedInstanceIfExists;
-(BOOL)isUILocked;
-(id)lockScreenViewController;
@end

@interface BBAction : NSObject
@property (nonatomic,assign) int actionType; 
@property (nonatomic,retain) NSURL* launchURL; 
+(id)actionWithCallblock:(id)callblock;
+(id)actionWithLaunchBundleID:(NSString *)id callblock:(id)block;
+(id)actionWithLaunchURL:(NSURL*)aurl callblock:(id)ablock;
@end


@interface TLAlertConfiguration : NSObject
-(id)initWithType:(long long)type;
-(void)setExternalToneFileURL:(id)urla;
@end

@interface BBSound : NSObject
-(void)setSoundType:(int)aye;
-(id)initWithSystemSoundID:(int)systemSoundID behavior:(int)behavior vibrationPattern:(id)pattern;
-(id)initWithSystemSoundPath:(id)arg1 behavior:(int)arg2 vibrationPattern:(id)arg3 ;
-(void)setSystemSoundID:(int)systemSoundID;
-(id)initWithToneAlert:(long long)toneAlert;
-(id)initWithToneAlertConfiguration:(id)toneAlertConf;
@end


@interface BBAttachments : NSObject
-(void)setPrimaryType:(int)atype;
@end


@interface BBBulletinRequest : NSObject
@property (nonatomic,retain) NSString *bulletinID; 
@property (nonatomic,retain) NSString *title; 
@property (nonatomic,retain) NSString *subtitle; 
@property (nonatomic,retain) NSString *message; 
@property (nonatomic,retain) NSString *sectionID;
@property (nonatomic,retain) NSString *section; 
@property (nonatomic,retain) BBSound *sound; 
@property (nonatomic,retain) NSDictionary *context; 
@property (nonatomic,retain) id unlockActionLabel;
@property (nonatomic,retain) NSDate *date; 
@property (nonatomic,retain) NSDate *lastInterruptDate; 
@property (nonatomic,retain) NSDate *recencyDate; 
@property (nonatomic,retain) NSDate *endDate; 
@property (nonatomic,retain) NSDate *publicationDate; 
@property (nonatomic,assign) BOOL hasEventDate; 
@property (nonatomic,assign) BOOL clearable; 
@property (nonatomic,assign) int dateFormatStyle;
@property (nonatomic,assign) int messageNumberOfLines;
@property (nonatomic,assign) int sectionSubtype;
@property (nonatomic,retain) BBAction *defaultAction; 
@property (nonatomic,copy)   BBAction * alternateAction; 
@property (nonatomic,copy)   BBAction * acknowledgeAction; 
@property (nonatomic,copy)   BBAction * snoozeAction; 
@property (nonatomic,retain) BBAction *raiseAction;
@property (nonatomic,assign) BOOL showsMessagePreview; 
@property (nonatomic,assign) BOOL suppressesMessageForPrivacy; 
@property (nonatomic,retain) NSString *unlockActionLabelOverride; 
@property (nonatomic,retain) NSString *bulletinVersionID; 
@property (nonatomic,retain) NSTimeZone *timeZone;
@property (assign,nonatomic) BOOL dateIsAllDay;
@property (nonatomic,retain) BBAttachments *attachments;
@property (nonatomic,retain) NSString *recordID;
@property (nonatomic,retain) NSString *publisherBulletinID;
-(void)publish;
-(void)setPrimaryAttachment:(BBAttachmentMetadata *)arg1 ;
@end
 
@interface BBBulletin : BBBulletinRequest
@end

@interface NCNotificationRequest : NSObject
-(BBBulletin*)bulletin;
@end

@interface NCNotificationLongLookViewController : NSObject
-(NCNotificationRequest*)notificationRequest;
@end
