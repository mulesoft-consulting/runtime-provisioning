# Dockerizing Mule EE
# Version: 0.1
# Based on: Oracle JDK
# Pull base image.
FROM ubuntu:16.04
MAINTAINER MuleSoft Professional Services

#Set project labels
LABEL com.mulesoft.runtime.container.baservices.version="1.0.0"
LABEL com.mulesoft.runtime.container.baservices..environment="Sandbox"
LABEL vendor="MuleSoft"

# Install Java.
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  apt-get update && \
  apt-get install software-properties-common python-software-properties -y && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Install required libraries
RUN apt-get update && apt-get install jq -y
RUN apt-get update && apt-get install -y dnsutils
RUN apt-get update && apt-get install -y unzip
RUN apt-get update && apt-get install -y curl

# MuleEE installation:
ENV MULE_VERSION=3.9.0
COPY ./mule-ee-distribution-standalone-$MULE_VERSION.zip /opt/

WORKDIR /opt
RUN unzip /opt/mule-ee-distribution-standalone-$MULE_VERSION.zip
RUN rm -f /opt/mule-ee-distribution-standalone-$MULE_VERSION.zip
RUN mv /opt/mule-ee-distribution-standalone-$MULE_VERSION mule
COPY ./arm_register_server.sh /opt/mule/bin/
ENV MULE_HOME=/opt/mule

# Mule License File installation
WORKDIR /opt/mule
COPY ./muleLicenseKey.lic /opt/mule/conf/
# Remove unnecesary files
RUN rm -Rf examples
# Define mount points
VOLUME ["/opt/mule/.mule"]

# Configure external access:
# HTTPS Port for Anypoint Platform communication
EXPOSE  443
# Mule remote debugger
EXPOSE  5000
# Mule JMX port (must match Mule config file)
EXPOSE  1098
# Mule Cluster ports
EXPOSE 5701
EXPOSE 54327
# HTTP Service Port
EXPOSE 8081
# HTTPS Service Port
EXPOSE 8091
# Environment and execution:
# CMD ["/opt/mule/bin/mule", "-M-Dmule.agent.enabled=false"]