#!/usr/bin/env bash

umask 027

#########################################################################################
# 
# Just like any other web server, Apache Tomcat should not be run with a privileged user. 
# Hence, we create a system user for Apache Tomcat, there is no need to change any
# permission, the tomcat group has the neccesary permisions and that group was created 
# at build time.
# 
# Creating the user here allows us to set the service user at run time if the 
# Env TOMCAT_SRV_USR is passed to the Run command
# 
#########################################################################################
id "$TOMCAT_SRV_USR" >/dev/null 2>&1
if [ $? != 0 ]; then
    # Only create the user if does not exists already    
    useradd -U -r -d $CATALINA_HOME -s /bin/false -u $TOMCAT_SRV_UID $TOMCAT_SRV_USR 
    chown -R 0:$TOMCAT_SRV_UID $CATALINA_HOME/ >/dev/null 2>&1
fi

CATALINA_OPTS_FILE=$CATALINA_HOME/conf/CATALINA_OPTS
JAVA_OPTS_FILE=$CATALINA_HOME/conf/JAVA_OPTS

ENV_FILE=$CATALINA_HOME/bin/setenv.sh

echo "CATALINA_HOME=\"$CATALINA_HOME\"" > $ENV_FILE
echo "JRE_HOME=\"$JRE_HOME\"" >> $ENV_FILE
[ -f $JAVA_OPTS_FILE ] && echo "$(cat $JAVA_OPTS_FILE)" >> $ENV_FILE
if [ "$TOMCAT_DBUG_PORT" != "-1" ]; then 
    echo "JAVA_OPTS=\"\$JAVA_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,address=*:\$TOMCAT_DBUG_PORT,server=y,suspend=n\"" >> $ENV_FILE
fi
[ -f $CATALINA_OPTS_FILE ] && echo "$(cat $CATALINA_OPTS_FILE)" >> $ENV_FILE
if [ "$TOMCAT_HTTP_PORT" != "-1" ]; then 
    # If HTTP Port defined delete the security-constraint from web.xml to be able to reach pages using HTTP
    # The security constraint section in web.xml goes from lines 4742 to 4750, we just delete it
    echo "CATALINA_OPTS=\"\$CATALINA_OPTS -Dport.http=\$TOMCAT_HTTP_PORT\"" >> $ENV_FILE
    sed -i "4742,4750d" ${CATALINA_HOME}/conf/web.xml 
else 
    # If No HTTP port provided, lett's delete the http connector line from server.xml
    sed -i "19d" ${CATALINA_HOME}/conf/server.xml 
fi
echo "CATALINA_OPTS=\"\$CATALINA_OPTS -Dport.https=\$TOMCAT_SSL_PORT\"" >> $ENV_FILE
echo "CATALINA_OPTS=\"\$CATALINA_OPTS -Djava.library.path=$CATALINA_HOME/lib\"" >> $ENV_FILE
echo "CATALINA_OPTS=\"\$CATALINA_OPTS -Dcerts.cert=$HTTP_TLS_CERTIFICATE\"" >> $ENV_FILE
echo "CATALINA_OPTS=\"\$CATALINA_OPTS -Dcerts.key=$HTTP_TLS_KEY\"" >> $ENV_FILE

# The next script imports the self signed certificate into the
# java keysotre, this is usefull when more than one tomcat-apr container is up and want to connect
# between each other using SSL 
$CATALINA_HOME/bin/import-certs.sh


# Transfer execution control to thetomcat service user
set -- gosu $TOMCAT_SRV_UID "$@"
exec "$@"
