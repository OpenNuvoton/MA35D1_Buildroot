
################################################################################
#
# M4-BSP
#
################################################################################

# Please keep in sync with package/nuvoton-ma35d1/m4-bsp/m4-bsp.mk
HOST_M4_BSP_VERSION = 1.0
HOST_M4_BSP_SOURCE = m4-bsp-$(PYTHON3_NUWRITER_VERSION).tar.gz
HOST_M4_BSP_SITE = $(call github,OpenNuvoton,MA35D1_RTP_BSP,master)
HOST_M4_BSP_LICENSE=MIT
HOST_M4_BSP_LICENSE_FILES=LICENSE
HOST_M4_BSP_DEPENDENCIES= host-gcc-arm-none-eabi host-nu-eclipse

define HOST_M4_BSP_BUILD_CMDS
	cp board/nuvoton/ma35d1/rtp_build.sh $(@D)
	(cd $(@D); \
		./rtp_build.sh ${HOST_DIR}/gcc-arm-none-eabi ${HOST_DIR}/nu-eclipse/eclipse . ${BINARIES_DIR}/RTP-BSP; \
	)
endef

define HOST_M4_BSP_INSTALL_CMDS
        (cd $(@D); \
        )
endef

$(eval $(host-generic-package))

