TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = DynamicIslandOffsetPrefs
DynamicIslandOffsetPrefs_FILES = IOCRootListController.m
DynamicIslandOffsetPrefs_FRAMEWORKS = UIKit
DynamicIslandOffsetPrefs_PRIVATE_FRAMEWORKS = Preferences
DynamicIslandOffsetPrefs_INSTALL_PATH = /Library/PreferenceBundles
DynamicIslandOffsetPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
