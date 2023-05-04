DEBUG=0
FINALPACKAGE=1
GO_EASY_ON_ME=1

THEOS_PACKAGE_SCHEME = rootless

THEOS_DEVICE_IP = 127.0.0.1 -p 2222

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/null.mk

all::
	xcodebuild CODE_SIGN_IDENTITY="" AD_HOC_CODE_SIGNING_ALLOWED=YES -scheme EdictusOBJC archive -archivePath Edictus.xcarchive PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"' | xcpretty && exit ${PIPESTATUS[0]}

after-stage::
	mv Edictus.xcarchive/Products/Applications $(THEOS_STAGING_DIR)/Applications
	rm -rf Edictus.xcarchive
	ldid -S $(THEOS_STAGING_DIR)/Applications/Edictus.app/Edictus
	ldid -SEdictus.entitlements $(THEOS_STAGING_DIR)/Applications/Edictus.app/Edictus


after-install::
	install.exec "killall \"Edictus\" || true"