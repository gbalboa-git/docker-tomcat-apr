#!/bin/bash

set -e

umask 027 #Default in Ubuntu is 022 (but we dont want to give any permissions to "others" for new files created duiring this process )

# Adjust permissions
chmod 750 $CATALINA_HOME/*
chmod 640 $CATALINA_HOME/certs/* 
chmod 640 $CATALINA_HOME/conf/* 
chmod 750 $CATALINA_HOME/conf/Catalina
chmod 750 $CATALINA_HOME/conf/Catalina/localhost 
chmod 640 $CATALINA_HOME/lib/* 

chmod 770 $CATALINA_HOME/logs 
chmod 770 $CATALINA_HOME/temp 
chmod 770 $CATALINA_HOME/work 

# This auths. are required only if deployment functionality (By Autodeploy at startup or Manager App) is required  
 chmod g+w $CATALINA_HOME/webapps 