################################################################################
#
# python3-nuwriter
#
################################################################################

# Please keep in sync with package/nuvoton-ma35d1/python3-nuwriter/python3-nuwriter.mk
PYTHON3_NUWRITER_VERSION = 1.0
PYTHON3_NUWRITER_SOURCE = nuwriter-$(PYTHON3_NUWRITER_VERSION).tar.gz
PYTHON3_NUWRITER_SITE = $(call github,OpenNuvoton,MA35D1_NuWriter,master)
HOST_PYTHON3_NUWRITER_SETUP_TYPE = setuptools
PYTHON3_NUWRITER_LICENSE = MIT
PYTHON3_NUWRITER_LICENSE_FILES = LICENSE
HOST_PYTHON3_NUWRITER_NEEDS_HOST_PYTHON = python3
HOST_PYTHON3_NUWRITER_DEPENDENCIES = \
	host-python3-pip

define HOST_PYTHON3_NUWRITER_BUILD_CMDS
	(cd $(@D); \
		$(HOST_DIR)/bin/pip3 install wheel crcmod pyusb usb crypto ecdsa tqdm pycryptodome \
	)
endef

define HOST_PYTHON3_NUWRITER_INSTALL_CMDS
	(cd $(@D); \
		$(HOST_DIR)/bin/pip3 install ./ \
	)
endef

$(eval $(host-generic-package))
