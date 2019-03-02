GO_EASY_ON_ME=1
include theos/makefiles/common.mk

TWEAK_NAME = libbulletin
libbulletin_FILES = libbulletin.xm
libbulletin_FRAMEWORKS = AudioToolbox UIKit
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
