TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = MyAnimeList
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MyAnimeListNSFW

MyAnimeListNSFW_FILES = Tweak.x
MyAnimeListNSFW_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
