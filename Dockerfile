#------------------------------------------------------------------------------
# Set the base image for subsequent instructions:
#------------------------------------------------------------------------------

FROM centos:7
MAINTAINER Giulio <>

#------------------------------------------------------------------------------
# Environment variables:
#------------------------------------------------------------------------------

ENV MESOS_VERSION="0.28.1" \
    MESOS_URL="http://repos.mesosphere.io/el/7/noarch/RPMS" \
    JENKINS_UC="https://updates.jenkins.io" \
    JENKINS_VERSION="2.6-1.1" \
    JENKINS_MESOS_VERSION="0.12.0"

#------------------------------------------------------------------------------
# Update the base image:
#------------------------------------------------------------------------------

RUN rpm --import http://mirror.centos.org/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7 \
    && yum update -y && yum clean all

#------------------------------------------------------------------------------
# Install libmesos:
#------------------------------------------------------------------------------

RUN yum install -y ${MESOS_URL}/mesosphere-el-repo-7-3.noarch.rpm \
    yum-utils subversion-libs apr-util && mkdir /tmp/mesos && cd /tmp/mesos \
    && yumdownloader mesos-${MESOS_VERSION} && rpm2cpio mesos*.rpm | cpio -idm \
    && cp usr/lib/libmesos-*.so /usr/lib/ && cd /usr/lib \
    && ln -s libmesos-*.so libmesos.so && rm -rf /tmp/mesos && yum clean all

#------------------------------------------------------------------------------
# Install jenkins:
#------------------------------------------------------------------------------

RUN rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key \
    && yum install -y java-1.8.0-openjdk-headless java-1.8.0-openjdk-devel wget openssl \
    && wget -q -O /etc/yum.repos.d/jenkins.repo \
       http://pkg.jenkins-ci.org/redhat/jenkins.repo \
    && yum install -y git jenkins-${JENKINS_VERSION} && yum clean all


#------------------------------------------------------------------------------
# Copy plugin dependencies:
#------------------------------------------------------------------------------

COPY plugins.sh /usr/local/bin/plugins.sh
RUN yum install unzip -y && yum clean all

#------------------------------------------------------------------------------
# Populate root file system:
#------------------------------------------------------------------------------

ADD rootfs /

#------------------------------------------------------------------------------
# Install plugins:
#------------------------------------------------------------------------------

RUN mkdir -p /var/lib/jenkins/plugins && cd /var/lib/jenkins/plugins \
&& /usr/local/bin/plugins.sh  /var/lib/jenkins/plugins.txt

#------------------------------------------------------------------------------
# Move jenkins dir in staging directory:
#------------------------------------------------------------------------------

RUN mv /var/lib/jenkins /var/lib/jenkins_staging


#------------------------------------------------------------------------------
# Expose ports and entrypoint:
#------------------------------------------------------------------------------

ENTRYPOINT ["/init"]
