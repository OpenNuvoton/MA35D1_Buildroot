################################################################################
#
# arm-trusted-firmware
#
################################################################################

ARM_TRUSTED_FIRMWARE_VERSION = $(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_VERSION))

ifeq ($(ARM_TRUSTED_FIRMWARE_VERSION),custom)
# Handle custom ATF tarballs as specified by the configuration
ARM_TRUSTED_FIRMWARE_TARBALL = $(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_TARBALL_LOCATION))
ARM_TRUSTED_FIRMWARE_SITE = $(patsubst %/,%,$(dir $(ARM_TRUSTED_FIRMWARE_TARBALL)))
ARM_TRUSTED_FIRMWARE_SOURCE = $(notdir $(ARM_TRUSTED_FIRMWARE_TARBALL))
else ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_GIT),y)
ARM_TRUSTED_FIRMWARE_SITE = $(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_REPO_URL))
ARM_TRUSTED_FIRMWARE_SITE_METHOD = git
else
# Handle stable official ATF versions
ARM_TRUSTED_FIRMWARE_SITE = $(call github,ARM-software,arm-trusted-firmware,$(ARM_TRUSTED_FIRMWARE_VERSION))
# The licensing of custom or from-git versions is unknown.
# This is valid only for the latest (i.e. known) version.
ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_LATEST_VERSION),y)
ARM_TRUSTED_FIRMWARE_LICENSE = BSD-3-Clause
ARM_TRUSTED_FIRMWARE_LICENSE_FILES = docs/license.rst
endif
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE)$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_LATEST_VERSION),y)
BR_NO_CHECK_HASH_FOR += $(ARM_TRUSTED_FIRMWARE_SOURCE)
endif

ARM_TRUSTED_FIRMWARE_INSTALL_IMAGES = YES

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_NEEDS_DTC),y)
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += host-dtc
endif

ifeq ($(BR2_TARGET_MA35D1_SECURE_BOOT),y)
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += host-python3 host-python3-nuwriter host-jq host-m4-bsp
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_NEEDS_ARM32_TOOLCHAIN),y)
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += host-arm-gnu-a-toolchain
endif

ARM_TRUSTED_FIRMWARE_PLATFORM = $(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_PLATFORM))

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_DEBUG),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += DEBUG=1
ARM_TRUSTED_FIRMWARE_IMG_DIR = $(@D)/build/$(ARM_TRUSTED_FIRMWARE_PLATFORM)/debug
else
ARM_TRUSTED_FIRMWARE_IMG_DIR = $(@D)/build/$(ARM_TRUSTED_FIRMWARE_PLATFORM)/release
endif

ARM_TRUSTED_FIRMWARE_MAKE_OPTS += \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	$(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES)) \
	PLAT=$(ARM_TRUSTED_FIRMWARE_PLATFORM)

ARM_TRUSTED_FIRMWARE_MAKE_ENV += \
	$(TARGET_MAKE_ENV) \
	ENABLE_STACK_PROTECTOR=$(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_SSP_LEVEL))

ifeq ($(BR2_ARM_CPU_ARMV7A),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += ARM_ARCH_MAJOR=7
else ifeq ($(BR2_ARM_CPU_ARMV8A),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += ARM_ARCH_MAJOR=8
endif

ifeq ($(BR2_arm),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += ARCH=aarch32
else ifeq ($(BR2_aarch64),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += ARCH=aarch64
endif

ifneq ($(call findstring,custom,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME)),)
DSIZE=$(shell expr $(shell printf "%d\n" $(TFA_CUSTOM_DDR_SIZE)) - $(shell printf "%d\n" 0x800000))
SBASE=$(shell expr $(shell printf "%d\n" $(TFA_CUSTOM_DDR_SIZE)) + $(shell printf "%d\n" 0x7F800000))
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_BL32_OPTEE),y)
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += optee-os
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += \
	BL32=$(BINARIES_DIR)/tee-header_v2.bin \
	BL32_EXTRA1=$(BINARIES_DIR)/tee-pager_v2.bin \
	BL32_EXTRA2=$(BINARIES_DIR)/tee-pageable_v2.bin
ARM_TRUSTED_FIRMWARE_FIP_OPTS += \
	--tos-fw $(BINARIES_DIR)/fip/enc_tee-header_v2.bin \
	--tos-fw-extra1 $(BINARIES_DIR)/fip/enc_tee-pager_v2.bin
ifeq ($(BR2_aarch64),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += SPD=opteed
endif
ifeq ($(BR2_arm),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += AARCH32_SP=optee
endif
endif # BR2_TARGET_ARM_TRUSTED_FIRMWARE_BL32_OPTEE

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_UBOOT_AS_BL33),y)
ARM_TRUSTED_FIRMWARE_UBOOT_BIN = $(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_UBOOT_BL33_IMAGE))
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += BL33=$(BINARIES_DIR)/$(ARM_TRUSTED_FIRMWARE_UBOOT_BIN)
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += uboot
ARM_TRUSTED_FIRMWARE_FIP_OPTS += --nt-fw $(BINARIES_DIR)/fip/enc_u-boot.bin
endif

ifeq ($(BR2_TARGET_VEXPRESS_FIRMWARE),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += SCP_BL2=$(BINARIES_DIR)/scp-fw.bin
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += vexpress-firmware
endif

ifeq ($(BR2_TARGET_BINARIES_MARVELL),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += SCP_BL2=$(BINARIES_DIR)/scp-fw.bin
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += binaries-marvell
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_LOAD_SCP_BL2),y)
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += host-m4-bsp
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += SCP_BL2=$(BINARIES_DIR)/$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_SCP_URL) NEED_SCP_BL2=yes
ARM_TRUSTED_FIRMWARE_FIP_OPTS += --scp_bl2 ${BINARIES_DIR}/fip/enc_rtp.bin
endif

ifeq ($(BR2_TARGET_MV_DDR_MARVELL),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MV_DDR_PATH=$(MV_DDR_MARVELL_DIR)
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += mv-ddr-marvell
endif

ARM_TRUSTED_FIRMWARE_MAKE_TARGETS = all

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_FIP),y)
ARM_TRUSTED_FIRMWARE_MAKE_TARGETS += fip
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += host-openssl
# fiptool only exists in newer (>= 1.3) versions of ATF, so we build
# it conditionally. We need to explicitly build it as it requires
# OpenSSL, and therefore needs to be passed proper variables to find
# the host OpenSSL.
define ARM_TRUSTED_FIRMWARE_BUILD_FIPTOOL
	if test -d $(@D)/tools/fiptool; then \
		$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D)/tools/fiptool \
			$(ARM_TRUSTED_FIRMWARE_MAKE_OPTS) \
			CPPFLAGS="$(HOST_CPPFLAGS)" \
			LDLIBS="$(HOST_LDFLAGS) -lcrypto" ; \
	fi

	if [ "${TFA_CPU800_CUSTOM_DDR}" == "y" ] || [ "${TFA_CPU1G_CUSTOM_DDR}" == "y" ]; then \
		cp $(BASE_DIR)/../board/nuvoton/ma35d1/ddr/$(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_DDR)) $(@D)/plat/$(call qstrip,$(BR2_TARGET_OPTEE_OS_PLATFORM))/$(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_PLATFORM))/include/custom_ddr.h; \
	fi
endef
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_LOAD_A35),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MA35D1_SCPBL2_BASE=$(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_LOAD_A35_BASE))
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_BL31),y)
ARM_TRUSTED_FIRMWARE_MAKE_TARGETS += bl31
ARM_TRUSTED_FIRMWARE_FIP_OPTS += --soc-fw $(BINARIES_DIR)/fip/enc_bl31.bin
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_BL31_UBOOT),y)
define ARM_TRUSTED_FIRMWARE_BL31_UBOOT_BUILD
# Get the entry point address from the elf.
	BASE_ADDR=$$($(TARGET_READELF) -h $(ARM_TRUSTED_FIRMWARE_IMG_DIR)/bl31/bl31.elf | \
	             sed -r '/^  Entry point address:\s*(.*)/!d; s//\1/') && \
	$(MKIMAGE) \
		-A $(MKIMAGE_ARCH) -O arm-trusted-firmware -C none \
		-a $${BASE_ADDR} -e $${BASE_ADDR} \
		-d $(ARM_TRUSTED_FIRMWARE_IMG_DIR)/bl31.bin \
		$(ARM_TRUSTED_FIRMWARE_IMG_DIR)/atf-uboot.ub
endef
define ARM_TRUSTED_FIRMWARE_BL31_UBOOT_INSTALL
	$(INSTALL) -m 0644 $(ARM_TRUSTED_FIRMWARE_IMG_DIR)/atf-uboot.ub \
		$(BINARIES_DIR)/atf-uboot.ub
endef
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += RESET_TO_BL31=1
ARM_TRUSTED_FIRMWARE_DEPENDENCIES += host-uboot-tools
endif

ifeq ($(BR2_TARGET_UBOOT_NEEDS_ATF_BL31_ELF),y)
define ARM_TRUSTED_FIRMWARE_BL31_UBOOT_INSTALL_ELF
	$(INSTALL) -D -m 0644 $(ARM_TRUSTED_FIRMWARE_IMG_DIR)/bl31/bl31.elf \
		$(BINARIES_DIR)/bl31.elf
endef
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_NEEDS_DTC),y)
ifeq ($(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME))),)
$(error No dts. Please check BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME))
endif
define ARM_TRUSTED_FIRMWARE_BL2_DTB_INSTALL
	$(INSTALL) -D -m 0644 $(ARM_TRUSTED_FIRMWARE_IMG_DIR)/fdts/$(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME)).dtb \
	$(BINARIES_DIR)/bl2.dtb;
endef
endif

ifeq ($(BR2_TARGET_MA35D1_SECURE_BOOT),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += FIP_DE_AES=1
endif
ARM_TRUSTED_FIRMWARE_MAKE_TARGETS += \
	$(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_TARGETS))

ifeq ($(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_PLATFORM)),ma35d1)
ifeq ($(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES)),)
ifeq ($(TFA_CPU800_WB128M),y)
	BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME="ma35d1-cpu800-wb-128m"
else ifeq ($(TFA_CPU800_WB256M),y)
	BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME="ma35d1-cpu800-wb-256m"
else ifeq ($(TFA_CPU800_WB512M),y)
	BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME="ma35d1-cpu800-wb-512m"
else ifeq ($(TFA_CPU1G_WB256M),y)
	BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME="ma35d1-cpu1g-wb-256m"
else ifeq ($(TFA_CPU1G_WB512M),y)
	BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME="ma35d1-cpu1g-wb-512m"
else ifeq ($(TFA_CPU800_MC1G),y)
	BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME="ma35d1-cpu800-mc-1g"
else ifeq ($(TFA_CPU1G_MC1G),y)
	BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME="ma35d1-cpu1g-mc-1g"
else ifeq ($(TFA_CPU800_CUSTOM_DDR),y)
	BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME="ma35d1-cpu800-custom-ddr"
else ifeq ($(TFA_CPU1G_CUSTOM_DDR),y)
	BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME="ma35d1-cpu1g-custom-ddr"
endif

ifneq ($(call findstring,128,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME)),)
	ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MA35D1_DRAM_SIZE=0x07800000 MA35D1_DDR_MAX_SIZE=0x08000000 \
					  MA35D1_DRAM_S_BASE=0x87800000 MA35D1_BL32_BASE=0x87800000
else ifneq ($(call findstring,256,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME)),)
	ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MA35D1_DRAM_SIZE=0x0F800000 MA35D1_DDR_MAX_SIZE=0x10000000 \
					  MA35D1_DRAM_S_BASE=0x8F800000 MA35D1_BL32_BASE=0x8F800000
else ifneq ($(call findstring,512,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME)),)
	ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MA35D1_DRAM_SIZE=0x1F800000 MA35D1_DDR_MAX_SIZE=0x20000000 \
					  MA35D1_DRAM_S_BASE=0x9F800000 MA35D1_BL32_BASE=0x9F800000
else ifneq ($(call findstring,custom,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_INTREE_DTS_NAME)),)
        ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MA35D1_DRAM_SIZE=${DSIZE} \
					  MA35D1_DDR_MAX_SIZE=$(TFA_CUSTOM_DDR_SIZE) \
					  MA35D1_DRAM_S_BASE=${SBASE} \
					  MA35D1_BL32_BASE=${SBASE}
else
	ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MA35D1_DRAM_SIZE=0x3F800000 MA35D1_DDR_MAX_SIZE=0x40000000 \
					  MA35D1_DRAM_S_BASE=0xAF800000 MA35D1_BL32_BASE=0xAF800000
endif
endif
endif

ifeq ($(TFA_MA35D1_PMIC_0),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MA35D1_PMIC=0 MA35D1_CPU_CORE=$(TFA_MA35D1_CPU_CORE_POWER)
else ifeq ($(TFA_MA35D1_PMIC_1),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MA35D1_PMIC=1 MA35D1_CPU_CORE=$(TFA_MA35D1_CPU_CORE_POWER)
else ifeq ($(TFA_MA35D1_PMIC_2),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MA35D1_PMIC=2 MA35D1_CPU_CORE=$(TFA_MA35D1_CPU_CORE_POWER)
else ifeq ($(TFA_MA35D1_PMIC_3),y)
ARM_TRUSTED_FIRMWARE_MAKE_OPTS += MA35D1_PMIC=3 MA35D1_CPU_CORE=$(TFA_MA35D1_CPU_CORE_POWER)
endif


define ARM_TRUSTED_FIRMWARE_BUILD_FIP
	if [ "${BR2_TARGET_MA35D1_SECURE_BOOT}" == "y" ]; then \
		cd ${BINARIES_DIR}; \
		if [ -d ${BINARIES_DIR}/fip ]; then \
			rm ${BINARIES_DIR}/fip -rf; \
		fi; \
		mkdir ${BINARIES_DIR}/fip; \
		cat ${TOPDIR}/board/nuvoton/ma35d1/nuwriter/en_fip.json | \
		${HOST_DIR}/bin/jq -r ".header.aeskey = \"${BR2_TARGET_MA35D1_AES_KEY}\"" | \
		${HOST_DIR}/bin/jq -r ".header.ecdsakey = \"${BR2_TARGET_MA35D1_ECDSA_KEY}\"" \
		> ${BINARIES_DIR}/fip/en_fip.json; \
		if [ "${BR2_TARGET_ARM_TRUSTED_FIRMWARE_BL31}" == "y" ]; then \
			cp ${ARM_TRUSTED_FIRMWARE_IMG_DIR}/bl31.bin ${BINARIES_DIR}/fip/enc.bin; \
			${HOST_DIR}/bin/python3 ${HOST_DIR}/bin/nuwriter.py -c ${BINARIES_DIR}/fip/en_fip.json>/dev/null; \
			cat conv/enc_enc.bin conv/header.bin >${BINARIES_DIR}/fip/enc_bl31.bin; \
			rm -rf `date "+%m%d-*"` conv pack; \
		fi; \
		if [ "${BR2_TARGET_ARM_TRUSTED_FIRMWARE_UBOOT_AS_BL33}" == "y" ]; then \
			cp ${BINARIES_DIR}/${BR2_TARGET_ARM_TRUSTED_FIRMWARE_UBOOT_BL33_IMAGE} ${BINARIES_DIR}/fip/enc.bin; \
			${HOST_DIR}/bin/python3 ${HOST_DIR}/bin/nuwriter.py -c ${BINARIES_DIR}/fip/en_fip.json>/dev/null; \
			cat conv/enc_enc.bin conv/header.bin >${BINARIES_DIR}/fip/enc_u-boot.bin; \
			rm -rf `date "+%m%d-*"` conv pack; \
		fi; \
		if [ "${BR2_TARGET_ARM_TRUSTED_FIRMWARE_BL32_OPTEE}" == "y" ]; then \
			cp $(BINARIES_DIR)/tee-header_v2.bin ${BINARIES_DIR}/fip/enc.bin; \
			${HOST_DIR}/bin/python3 ${HOST_DIR}/bin/nuwriter.py -c ${BINARIES_DIR}/fip/en_fip.json; \
			cat conv/enc_enc.bin conv/header.bin >${BINARIES_DIR}/fip/enc_tee-header_v2.bin; \
			rm -rf `date "+%m%d-*"` conv pack; \
			cp $(BINARIES_DIR)/tee-pager_v2.bin ${BINARIES_DIR}/fip/enc.bin; \
			${HOST_DIR}/bin/python3 ${HOST_DIR}/bin/nuwriter.py -c ${BINARIES_DIR}/fip/en_fip.json>/dev/null; \
			cat conv/enc_enc.bin conv/header.bin >${BINARIES_DIR}/fip/enc_tee-pager_v2.bin; \
			rm -rf `date "+%m%d-*"` conv pack; \
		fi; \
		if [ "${BR2_TARGET_ARM_TRUSTED_FIRMWARE_LOAD_SCP_BL2}" == "y" ]; then \
			cp $(BINARIES_DIR)/$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_SCP_URL) ${BINARIES_DIR}/fip/enc.bin; \
			${HOST_DIR}/bin/python3 ${HOST_DIR}/bin/nuwriter.py -c ${BINARIES_DIR}/fip/en_fip.json>/dev/null; \
			cat conv/enc_enc.bin conv/header.bin >${BINARIES_DIR}/fip/enc_rtp.bin; \
			rm -rf `date "+%m%d-*"` conv pack; \
		fi; \
		rm ${BINARIES_DIR}/fip/enc.bin ${BINARIES_DIR}/fip/en_fip.json; \
		if test -f $(@D)/tools/fiptool/fiptool; then \
			$(@D)/tools/fiptool/fiptool create \
			${ARM_TRUSTED_FIRMWARE_FIP_OPTS} \
			$(ARM_TRUSTED_FIRMWARE_IMG_DIR)/fip.bin; \
		fi; \
	fi
endef

define ARM_TRUSTED_FIRMWARE_BUILD_CMDS
	$(ARM_TRUSTED_FIRMWARE_BUILD_FIPTOOL)
	$(ARM_TRUSTED_FIRMWARE_MAKE_ENV) $(MAKE) -C $(@D) \
		$(ARM_TRUSTED_FIRMWARE_MAKE_OPTS) \
		$(ARM_TRUSTED_FIRMWARE_MAKE_TARGETS)
	$(ARM_TRUSTED_FIRMWARE_BUILD_FIP)
	$(ARM_TRUSTED_FIRMWARE_BL31_UBOOT_BUILD)
endef

define ARM_TRUSTED_FIRMWARE_INSTALL_IMAGES_CMDS
	$(foreach f,$(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_IMAGES)), \
		cp -dpf $(ARM_TRUSTED_FIRMWARE_IMG_DIR)/$(f) $(BINARIES_DIR)/
	)
	$(ARM_TRUSTED_FIRMWARE_BL31_UBOOT_INSTALL)
	$(ARM_TRUSTED_FIRMWARE_BL31_UBOOT_INSTALL_ELF)
	$(ARM_TRUSTED_FIRMWARE_BL2_DTB_INSTALL)
endef

# Configuration check
ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE)$(BR_BUILDING),yy)

ifeq ($(ARM_TRUSTED_FIRMWARE_VERSION),custom)
ifeq ($(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_TARBALL_LOCATION))),)
$(error No tarball location specified. Please check BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_TARBALL_LOCATION))
endif
endif

ifeq ($(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_GIT),y)
ifeq ($(call qstrip,$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_REPO_URL)),)
$(error No repository specified. Please check BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_REPO_URL)
endif
endif

endif

$(eval $(generic-package))
