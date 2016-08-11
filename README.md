# libbulletin
Simple iOS library that displays simple or complex bulletins

Usage:
-----

Show simple bulletin with bundle image:

    [[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:@"Hey!" message:@"Come over!" bundleID:@"com.name.id"];

Show simple bulletin with <strong>custom</strong> bundle image:

    [[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:@"Hey!" message:@"Come over!" overrideBundleImage:someUIImage];

Show simple bulletin with custom sound:

    [[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:@"Hey!" message:@"Come over!" overrideBundleImage:someUIImage soundPath:soundToPlay];


<strong>That's it!</strong>

Works across iOS 5 to 9.3.3.

All methods:
-----------

    -(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg bundleID:(NSString *)bundleID;
    -(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg bundleID:(NSString *)bundleID soundPath:(NSString *)soundPath;
    -(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg bundleID:(NSString *)bundleID soundID:(int)inSoundID;
    -(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg overrideBundleImage:(UIImage *)bundleImage;
    -(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg overrideBundleImage:(UIImage *)bundleImage soundPath:(NSString *)inSoundPath;
    -(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg inOverridBundleImage:(UIImage *)bundleImage soundID:(int)soundID;
    -(id)showBulletinWithTitle:(NSString *)title message:(NSString *)msg bundleID:(NSString *)bundleID hasSound:(BOOL)hasSound soundID:(int)soundID vibrateMode:(int)vibrate soundPath:(NSString *)soundPath attachmentImage:(UIImage *)attachmentImage overrideBundleImage:(UIImage *)overrideBundleImage;
	
