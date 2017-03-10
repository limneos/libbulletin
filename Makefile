include $(THEOS)/makefiles/common.mk

TWEAK_NAME = libbulletin
libbulletin_FILES = JBBulletinManager.m Tweak.xm
libbulletin_FRAMEWORKS = AudioToolbox UIKit
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
