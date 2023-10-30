
################################################################################
#
# gcc-arm-none-eabi
#
################################################################################

# Please keep in sync with package/nuvoton-ma35d1/gcc-arm-none-eabi/gcc-arm-none-eabi.mk
GCC_ARM_NONE_EABI_VERSION=1.0.0
GCC_ARM_NONE_EABI_SOURCE=gcc-arm-none-eabi-7-2017-q4-major-linux.tar.bz2
GCC_ARM_NONE_EABI_SITE=https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/7-2017q4
GCC_ARM_NONE_EABI_LICENSE=GPLv3
GCC_ARM_NONE_EABI_LICENSE_FILES=LICENSE

define HOST_GCC_ARM_NONE_EABI_INSTALL_CMDS
	(cd $(@D); \
		install -d ${HOST_DIR}/gcc-arm-none-eabi; \
		cp -r ./ ${HOST_DIR}/gcc-arm-none-eabi; \
	)
endef

$(eval $(host-generic-package))

