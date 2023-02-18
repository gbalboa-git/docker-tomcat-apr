# ################### Start of Base ###########################################
# 
# The objective of Base stage is to install Java, gosu and APR libraries on an
# Ubuntu Image.
# 
# Also in the base stage defines the Enviroment variables to run Tomcat 
# 
# ############################################################################### 

FROM ubuntu as base
ARG VERSION=10.1.5
ARG NATIVE_VERSION=2.0.2 
ARG DEFAULT_JRE_PKG=default-jdk
ARG PORT_HTTP=-1
ARG PORT_SSL=8443
ARG TOMCAT_SERVICE_USR_NAME=tomcat
ARG TOMCAT_SERVICE_USR_UID=997
ARG DBUG_PORT=-1

ENV TOMCAT_VERSION=${VERSION}
ENV TOMCAT_NATIVE_VERSION=${NATIVE_VERSION}
ENV CATALINA_HOME=/opt/tomcat
ENV JRE_HOME=/usr/lib/jvm/default-java
ENV HTTP_TLS_CERTIFICATE=$CATALINA_HOME/certs/domain.crt
ENV HTTP_TLS_KEY=$CATALINA_HOME/certs/domain.key
ENV TOMCAT_SRV_USR=$TOMCAT_SERVICE_USR_NAME
ENV TOMCAT_SRV_UID=$TOMCAT_SERVICE_USR_UID
ENV TOMCAT_HTTP_PORT=$PORT_HTTP
ENV TOMCAT_SSL_PORT=$PORT_SSL
ENV TOMCAT_DBUG_PORT=$DBUG_PORT


RUN apt-get update \ 
    && apt-get install --no-install-recommends -y \
    ${DEFAULT_JRE_PKG} \
    gosu \
    libaprutil1 \
    && rm -rf /var/lib/apt/lists/*

# ################### Start of Stage2 ###########################################
# 
# The objective of Stage2 is to download and install tomcat into $CATALINA_HOME,
# This stage extracts the tomcat content and also extract the APR native library 
# source code located in the tomcat-native.tar.gz file inside bin directory as
# mentioned in tomcat dumentation. 
# 
# The compiled libraries wil be stored in lib directory
# 
# ###############################################################################  
FROM base as tomcat-installation

RUN apt-get update \   
    && apt-get install --no-install-recommends -y \
    gcc \
    libapr1-dev \
    libssl-dev \ 
    make \ 
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR ${CATALINA_HOME}

COPY Stage2/install.sh  ./

RUN ./install.sh \    
    && find ${CATALINA_HOME}/ -maxdepth 1 -type f -delete

# ################### Start of Stage3 ###########################################
# 
# The objective of Stage3 is to overwrite tomcat files with our customization,
# and seth the directories permissions
# 
# ###############################################################################  
FROM tomcat-installation as tomcat-customizing

COPY --from=tomcat-installation ${CATALINA_HOME}/ ${CATALINA_HOME}/

WORKDIR ${CATALINA_HOME}

COPY Stage3/ ./

RUN ./set-auth.sh \        
    && rm -f set-auth.sh

# ############################## Start of final Stage #####################################
FROM base as final-stage

COPY --from=tomcat-customizing ${CATALINA_HOME}/ ${CATALINA_HOME}/

WORKDIR ${CATALINA_HOME}

# Expose Apache Secure port
EXPOSE ${TOMCAT_SSL_PORT}/tcp

ENTRYPOINT [ "bin/entrypoint.sh" ]

# Launch Tomcat
CMD ["bin/catalina.sh","run", "-security"]

LABEL org.balvigu.maintainer="Gustavo Balboa <gbalboa@hotmail.com>" 
LABEL org.balvigu.name="Tomcat-APR"
LABEL org.balvigu.description="Apache Tomcat preconfigured to use APR implementation, SecurityManager, TSL, User passwords encrypted and running with a non root user"
LABEL org.balvigu.version="2.0"