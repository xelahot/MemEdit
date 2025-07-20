ARCHS = arm64e
THEOS_PACKAGE_SCHEME = rootless
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
TARGET=iphone:16.5:15.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MemEditPref

DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

MemEditPref_FILES = $(wildcard *.mm)
MemEditPref_INSTALL_PATH = /Library/PreferenceBundles
MemEditPref_FRAMEWORKS = UIKit
MemEditPref_PRIVATE_FRAMEWORKS = Preferences
MemEditPref_LIBRARIES = Xelahot
MemEditPref_CCFLAGS = -std=c++11 -fno-rtti -DNDEBUG
MemEditPref_CFLAGS = -fobjc-arc #-w #-Wno-deprecated -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
