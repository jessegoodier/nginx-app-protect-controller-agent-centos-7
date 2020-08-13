#!/bin/bash -x

MINIMAL_SUPPORTED_VERSION=22
LATEST_PLUS_VERSION=22

if ! [[ $PLUS_VERSION -ge $MINIMAL_SUPPORTED_VERSION ]]; then
  PLUS_VERSION=$(nginx -v 2>&1 | awk -F"[-()]+" '/nginx-plus-r/{print substr($4,2)}')

  if ! [[ $PLUS_VERSION -ge $MINIMAL_SUPPORTED_VERSION ]]; then
    PLUS_VERSION=$LATEST_PLUS_VERSION
  fi
fi

set -e -o pipefail

TARBALL=${TARBALL:-cas.tar.gz}
WORK_DIR=/var/tmp/packages-repository/cas

if [ ! -d "${WORK_DIR}" ]; then
  mkdir -p ${WORK_DIR}
  tar xvzf ${TARBALL} -C $WORK_DIR
fi

cat << EOF > /etc/yum.repos.d/nginx-cas.repo
[nginx-cas]
name=nginx controller app protect repo
baseurl=file://${WORK_DIR}/centos/\$releasever/\$basearch
gpgcheck=1
enabled=1
gpgkey=file://${WORK_DIR}/nginx-signing.key
EOF

yum install -y epel-release
yum install -y cas-${PLUS_VERSION}
