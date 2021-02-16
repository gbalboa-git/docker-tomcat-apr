#!/bin/bash

set -e

umask 027 #Default in Ubuntu is 022 (but we dont want to give any permissions to "others" for new files created duiring this process )

#Download and extract the content to $CATALINA_HOME
MAJOR_VER=$(echo "${TOMCAT_VERSION}" | cut -d '.' -f1 )
TOMCAT_DOWNLOAD_FILE=apache-tomcat-${TOMCAT_VERSION}.tar.gz
TOMCAT_DOWNLOAD_URL=https://downloads.apache.org/tomcat/tomcat-${MAJOR_VER}/v${TOMCAT_VERSION}/bin/$TOMCAT_DOWNLOAD_FILE
wget "$TOMCAT_DOWNLOAD_URL"
tar xzf $TOMCAT_DOWNLOAD_FILE -C ${CATALINA_HOME} --strip-components=1

# Now lets delete all Tomcat default Applications except manager, host-manager.
rm -rf ${CATALINA_HOME}/webapps/ROOT/ >/dev/null 2>&1
rm -rf ${CATALINA_HOME}/webapps/examples/ >/dev/null 2>&1
rm -rf ${CATALINA_HOME}/webapps/docs/

# Remove all windows .bat files from bin directory (not needed)
rm -rf ${CATALINA_HOME}/bin/*.bat >/dev/null 2>&1

# Lets extract and compile the tomcat native libraries (for use of APR)
# cd $CATALINA_HOME/bin/
tar xzf $CATALINA_HOME/bin/tomcat-native.tar.gz -C ${CATALINA_HOME}/bin
cd $CATALINA_HOME/bin/tomcat-native-1.2.25-src/native/
$CATALINA_HOME/bin/tomcat-native-1.2.25-src/native/configure \
                  --with-java-home=$JRE_HOME \
                  --with-ssl=yes \
                  --prefix=$CATALINA_HOME
make && make install

# At this point the libraries are installed so lets delete the source files
# that we used to compile it.
rm -rf ${CATALINA_HOME}/bin/tomcat-native-1.2.25-src >/dev/null 2>&1
rm -f ${CATALINA_HOME}/bin/tomcat-native.tar.gz >/dev/null 2>&1

# Create the setenv.sh file to configure tomcat service with the env 
# variables when start, the file will be filled by the entrypoint.sh script
# in the final stage
touch $CATALINA_HOME/bin/setenv.sh && chmod +x $CATALINA_HOME/bin/setenv.sh

# Create the Self signed Certificate and its directory
mkdir $CATALINA_HOME/certs # To store the certificates 
openssl req \
  -newkey rsa:4096 -nodes -sha256 -keyout $HTTP_TLS_KEY \
  -x509 -days 365 -out $HTTP_TLS_CERTIFICATE -batch
