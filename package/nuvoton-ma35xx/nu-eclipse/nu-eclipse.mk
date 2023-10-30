
################################################################################
#
# nu-eclipse
#
################################################################################

# Please keep in sync with package/nuvoton-ma35d1/nu-eclipse/nu-eclipse.mk
NU_ECLIPSE_SOURCE=NuEclipse_V1.01.018_Linux_Setup.tar.gz
NU_ECLIPSE_SITE=https://www.nuvoton.com/export/resource-files

define HOST_NU_ECLIPSE_INSTALL_CMDS
	(cd $(@D); \
		install -d ${HOST_DIR}/nu-eclipse; \
		cp -r ./ ${HOST_DIR}/nu-eclipse; \
	)
endef

$(eval $(host-generic-package))

