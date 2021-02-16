#!/bin/bash
 
#  keytool -delete -cacerts -alias myself
# keytool -importcert -noprompt -keystore ${KEYSTORE} -storepass changeit -file $HTTP_TLS_CERTIFICATE -alias "myself" >/dev/null 2>&1
# keytool -list -keystore ${JRE_HOME}/lib/security/cacerts -storepass changeit -alias "myself"
# if [ ! $? -eq 0 ]; then
#   keytool -importcert -noprompt -keystore ${JRE_HOME}/lib/security/cacerts -storepass changeit -file $HTTP_TLS_CERTIFICATE -alias "myself"
# fi

keytool -list -cacerts -storepass changeit -alias "myself" >/dev/null 2>&1
if [ ! $? -eq 0 ]; then 
  # echo "importing certificates..."
  keytool -importcert -noprompt -cacerts -storepass changeit -file $HTTP_TLS_CERTIFICATE -alias "myself" >/dev/null 2>&1
fi