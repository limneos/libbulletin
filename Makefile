include theos/makefiles/common.mk

TWEAK_NAME = libbulletin
libbulletin_FILES = Tweak.xm
libbulletin_FRAMEWORKS = AudioToolbox
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
