#!/bin/bash


if [  -z "$(which yum)" ] ; then
    echo "Yum command does not exist, so just exit"
    exit 0
fi

ADD_SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    ADD_SUDO_PREFIX=""
fi

VERSION_ID=7
if [ -z "$(grep "http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS" /etc/yum.repos.d/*)" ] ; then
    if [ ! -f "/etc/yum.repos.d/CentOS-Base.repo" ] ; then
        ${ADD_SUDO_PREFIX} touch "/etc/yum.repos.d/CentOS-Base.repo"
        ${ADD_SUDO_PREFIX} chmod 755 "/etc/yum.repos.d/CentOS-Base.repo"
    fi

echo '[base-SRPMS]
name=CentOS-$releasever - Base SRPMS
baseurl=http://mirror.centos.org/centos/$releasever/os/SRPMS/
gpgcheck=1
gpgkey=http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-$releasever
priority=1
enabled=1

#released updates
[update-SRPMS]
name=CentOS-$releasever - Updates SRPMS
baseurl=http://mirror.centos.org/centos/$releasever/updates/SRPMS/
gpgcheck=1
gpgkey=http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-$releasever
priority=1
enabled=1' >>  /etc/yum.repos.d/CentOS-Base.repo


${ADD_SUDO_PREFIX} yum update

fi

${ADD_SUDO_PREFIX} yum install -y -q yum-utils
${ADD_SUDO_PREFIX} yumdownloader --source kernel
rpmbuild --rebuild kernel-*.src.rpm
${ADD_SUDO_PREFIX} rpm -Uhv kernel-debuginfo-*rpm

