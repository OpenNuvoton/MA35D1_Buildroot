################################################################################
#
# python3-pip
#
################################################################################

PYTHON3_PIP_VERSION = 21.3
PYTHON3_PIP_SOURCE = pip-$(PYTHON3_PIP_VERSION).tar.gz
PYTHON3_PIP_SITE = https://files.pythonhosted.org/packages/00/5f/d6959d6f25f202e3e68e3a53b815af42d770c829c19382d0acbf2c3e2112
HOST_PYTHON3_PIP_SETUP_TYPE = setuptools
PYTHON3_PIP_LICENSE = MIT
PYTHON3_PIP_LICENSE_FILES = LICENSE.txt
PYTHON3_PIP_CPE_ID_VENDOR = pypa
PYTHON3_PIP_CPE_ID_PRODUCT = pip
HOST_PYTHON3_PIP_NEEDS_HOST_PYTHON = python3

$(eval $(host-python-package))
