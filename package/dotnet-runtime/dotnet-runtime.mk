################################################################################
#
# dotnet-runtime
#
################################################################################
DOTNET_RUNTIME_VERSION = 3.1.26
DOTNET_RUNTIME_SITE = https://download.visualstudio.microsoft.com/download/pr/cb0e8b4b-7b2b-40cc-b7a6-30f0d4fabe6c/f5cb06cbb1b1b5d198792333b3db235a

DOTNET_RUNTIME_SOURCE = dotnet-runtime-$(DOTNET_RUNTIME_VERSION)-linux-arm64.tar.gz
DOTNET_RUNTIME_LICENSE = MIT
DOTNET_RUNTIME_LICENSE_FILES = LICENSE.txt

# Runtime could be installed in the global location [/usr/share/dotnet] and
# will be picked up automatically.
# As alternative, it is possible to use the DOTNET_ROOT environment variable
# to specify the runtime location or register the runtime location in
# [/etc/dotnet/install_location] 
# This script will install runtime to
# /usr/share/dotnet-runtime-$(DOTNET_RUNTIME_VERSION)
define DOTNET_RUNTIME_INSTALL_TARGET_CMDS
    cp -R $(@D) $(TARGET_DIR)/usr/share/
endef

$(eval $(generic-package))
