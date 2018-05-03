# Dockerizing Mule EE
# Version: 0.1
# Based on: openjdk
FROM openjdk:8
MAINTAINER MuleSoft

#Set project labels
LABEL com.mulesoft.runtime.container.version="0.0.1"
LABEL com.mulesoft.runtime.container.environment="Sandbox"
LABEL vendor="MuleSoft"

# Install jq
RUN apt-get update && apt-get install jq -y

# MuleEE installation:
ENV MULE_VERSION=3.8.6
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