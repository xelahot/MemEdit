ARCHS = arm64e
THEOS_PACKAGE_SCHEME = rootless
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
TARGET=iphone:16.5:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MemEdit

MemEdit_CCFLAGS = -std=c++11 -fno-rtti -DNDEBUG -Wno-vla-extension
MemEdit_CFLAGS = -fobjc-arc -Wno-deprecated -Wno-deprecated-declarations
MemEdit_FILES = Tweak.xm $(wildcard **/*.mm)
MemEdit_FRAMEWORKS = UIKit
MemEdit_LIBRARIES = Xelahot
#GO_EASY_ON_ME = 1

SUBPROJECTS += MemEditPref

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	@echo "Applying permissions..."
	find $(THEOS_STAGING_DIR) -type f -exec chmod 644 {} \;
	find $(THEOS_STAGING_DIR) -type f \( -name 'postinst' -o -name 'prerm' \) -exec chmod 755 {} \;
	find $(THEOS_STAGING_DIR) -type d -exec chmod 755 {} \;