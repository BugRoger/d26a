#!/bin/bash

DRIVER_ARCHIVE=NVIDIA-Linux-x86_64-${DRIVER_VERSION}
SITE=us.download.nvidia.com/XFree86/Linux-x86_64

curl -s -L http://${SITE}/${DRIVER_VERSION}/${DRIVER_ARCHIVE}.run -o ${DRIVER_ARCHIVE}.run
chmod +x ${DRIVER_ARCHIVE}.run && ./${DRIVER_ARCHIVE}.run -x && mv ${DRIVER_ARCHIVE} /build

/build/nvidia-installer -s -n --kernel-source-path=/usr/src/linux \
  --no-check-for-alternate-installs --no-opengl-files \
  --kernel-install-path=${PWD} --log-file-name=${PWD}/nvidia-installer.log || \
  echo "nspawn fails as expected. Because kernel modules can't install in the container"

find /build        -maxdepth 1 -name "nvidia-*" -executable -exec cp {} /opt/bin/ \; 
find /build        -maxdepth 1 -name "*.so.*"               -exec cp {} /usr/lib64/ \; 
find /build/kernel -maxdepth 1 -name "*.ko"                 -exec cp {} /usr/lib64/modules/$(uname -r)/video \; 
