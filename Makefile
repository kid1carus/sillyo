include /var/theos/makefiles/common.mk

TWEAK_NAME = sillyo
sillyo_FILES = Tweak.xm

include /var/theos/makefiles/tweak.mk

after-install::
	install.exec "killall -9 Sileo"
