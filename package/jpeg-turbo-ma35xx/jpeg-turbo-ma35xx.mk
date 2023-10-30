################################################################################
#
# jpeg-turbo-MA35XX
#
################################################################################

JPEG_TURBO_MA35XX_VERSION = 2.1.3
JPEG_TURBO_MA35XX_SOURCE = libjpeg-turbo-$(JPEG_TURBO_MA35XX_VERSION).tar.gz
JPEG_TURBO_MA35XX_SITE = https://downloads.sourceforge.net/project/libjpeg-turbo/$(JPEG_TURBO_MA35XX_VERSION)
JPEG_TURBO_MA35XX_LICENSE = IJG (libjpeg), BSD-3-Clause (TurboJPEG), Zlib (SIMD)
JPEG_TURBO_MA35XX_LICENSE_FILES = LICENSE.md README.ijg
JPEG_TURBO_MA35XX_CPE_ID_VENDOR = libjpeg-turbo
JPEG_TURBO_MA35XX_CPE_ID_PRODUCT = libjpeg-turbo
JPEG_TURBO_MA35XX_INSTALL_STAGING = YES
JPEG_TURBO_MA35XX_PROVIDES = jpeg
JPEG_TURBO_MA35XX_DEPENDENCIES = host-pkgconf

JPEG_TURBO_MA35XX_CONF_OPTS = -DWITH_JPEG8=ON -DWITH_VC8000=1

ifeq ($(BR2_STATIC_LIBS),y)
JPEG_TURBO_MA35XX_CONF_OPTS += -DENABLE_STATIC=ON -DENABLE_SHARED=OFF
else ifeq ($(BR2_SHARED_STATIC_LIBS),y)
JPEG_TURBO_MA35XX_CONF_OPTS += -DENABLE_STATIC=ON -DENABLE_SHARED=ON
else ifeq ($(BR2_SHARED_LIBS),y)
JPEG_TURBO_MA35XX_CONF_OPTS += -DENABLE_STATIC=OFF -DENABLE_SHARED=ON
endif

ifeq ($(BR2_PACKAGE_JPEG_SIMD_SUPPORT),y)
JPEG_TURBO_MA35XX_CONF_OPTS += -DWITH_SIMD=ON
# x86 simd support needs nasm
JPEG_TURBO_MA35XX_DEPENDENCIES += $(if $(BR2_X86_CPU_HAS_MMX),host-nasm)
else
JPEG_TURBO_MA35XX_CONF_OPTS += -DWITH_SIMD=OFF
endif

# Ensure that jpeg-turbo is compiled with -fPIC to allow linking the static
# libraries with dynamically linked programs. This is not a requirement
# for most architectures but is mandatory for ARM.
# This allow to avoid link issues with BR2_SSP_ALL:
# jsimd_none.c.o: relocation R_AARCH64_ADR_PREL_PG_HI21 against external symbol `__stack_chk_guard@@GLIBC_2.17'
# can not be used when making a shared object; recompile with -fPIC
ifeq ($(BR2_STATIC_LIBS),)
JPEG_TURBO_MA35XX_CONF_OPTS += -DCMAKE_POSITION_INDEPENDENT_CODE=ON
endif

ifeq ($(BR2_PACKAGE_JPEG_TURBO_MA35XX_TOOLS),)
define JPEG_TURBO_MA35XX_REMOVE_TOOLS
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/,cjpeg djpeg jpegtran rdjpgcom tjbench wrjpgcom)
endef
JPEG_TURBO_MA35XX_POST_INSTALL_TARGET_HOOKS += JPEG_TURBO_MA35XX_REMOVE_TOOLS
endif

$(eval $(cmake-package))
