# Docker Tomcat - APR

## Description

This project is intended to create an Docker image of Apache Tomcat with the [Apache Portable Runtime (APR) based Native library for Tomcat](https://tomcat.apache.org/tomcat-9.0-doc/apr.html) installed and enabled. 

The default configuration of the resulting image includes the following:

* SSL Enabled with a default self signed certificate that can be replaced with your ouw certificate using secrets or bind mounts. 
* Credential Handler with PBKDF2WithHmacSHA512 algorithm to avoid having the users passwrods in tomcat-users.xml as plain text. 
* Service running with a non root user. The UID of the tomcat user can be configured with the TOMCAT_SRV_UID env variable.
* The HTTP port is disabled by default, but can be enabled if the TOMCAT_HTTP_PORT is defined
* Debug functionality (for development enviroments) is disabled by default but can be enabled if TOMCAT_DBUG_PORT is defined
* [Security Manager](https://tomcat.apache.org/tomcat-9.0-doc/security-manager-howto.html#Configuring_Tomcat_With_A_SecurityManager) Enabled by default with some security settings enabled like suhut down port disabled by default, please read the Tomcat [Security Considerations](https://tomcat.apache.org/tomcat-9.0-doc/security-howto.html)  official documentation.
* The resultant image does not contains the examples, ROOT and Documentation applications, only Manager and Host Manager.
* You can add aditional Java options or Catalina optionss adding CATALINA_OPTS and/or JAVA_OPTS text files to the conf directory. (See examples section)

## How to use it

### Running the default image

Available enviroment vars:
* **HTTP_TLS_CERTIFICATE:** This option can be used if want to bind mount your own certificate and want to use a different name than the defult.  Default value: /usr/opt/tomcat/certs/domain.crt
* **HTTP_TLS_KEY:** This option can be used if want to bind mount your own certificate KEY and want to use a different name than the defult.  Default value: /usr/opt/tomcat/certs/domain.key
* **TOMCAT_HTTP_PORT:**: Define the container HTTP port (-1 or omit
 to disable http. This is default)
* **TOMCAT_SSL_PORT:** Defines the container HTTPS port (Default 8443)
* **TOMCAT_SRV_USR:** Defines the username for service user (default: tomcat)
* **TOMCAT_SRV_UID:** Defines the UID for the service user (default: 997)
* **TOMCAT_DBUG_PORT:** Define the container HTTP DEBUG port (-1 or omit
 to disable debugging options. This is default)


#### Examples

To run a container with Tomcat v9.0.41 with default options using the default image (you can use you own image if you build it, see the section below) and listening on host ssl port 443:
```
root@host:# docker run -p 443:8443 gbalboa72/tomcat-apr:latest 
``` 

To run a container with Tomcat v9.0.41 with HTTP enabled in port 8080 HTTPS in default port (8443) and Debug options enabled in port 8000, published on host HTTP/80 Debug/8000 and HTTPS/443:

```
root@host:# docker run \ 
              -e TOMCAT_HTTP_PORT=8080 \
              -e TOMCAT_DBUG_PORT=8000 \
              -p 443:8443 \
              -p 80:8080 \
              -p 8000:8000 \  
              gbalboa72/tomcat-apr:latest 
``` 

The following example overides many default configuration files, the catalina policy (required for security cutomizing of your app when running in Security Manager), you must adapt the catalina policy to be able to run your apps, please read the [Security Manager How To](https://tomcat.apache.org/tomcat-9.0-doc/security-manager-howto.html#Configuring_Tomcat_With_A_SecurityManager) to know how to do it, also overrides the logging properties file with your own logging config and finnaly overrides the self signed certificate with you own certificates using a different name cor cert and key files:

```
root@host:# docker run \          
          -p 443:8443 \          
          -v /path/to/your/catalina.policy:/opt/tomcat/conf/catalina.policy:ro \
          -v /path/to/your/logging.properties:/opt/tomcat/conf/logging.properties:ro \
          -v /path/to/your/certs:/opt/tomcat/certs:ro \
          -e HTTP_TLS_CERTIFICATE=YourOwn.crt \
          -e HTTP_TLS_KEY=YourOwn.key \ 
          gbalboa72/tomcat-apr:latest 
``` 


An example of how to edit the catalina policy to grant all permissions to your app. Copy the default policy located in **_$CATALINA_HOME/conf/catalina.policy_** directory to your host, edit the file and add the following line to the end of the file, please notice that **\<your_app_name\>** must be replaced with the name that you set for your app in the webapps folder.

Please review the Tomcat Official documentation for [Security Manager](https://tomcat.apache.org/tomcat-9.0-doc/security-manager-howto.html#Configuring_Tomcat_With_A_SecurityManager):

```
grant codeBase "file:${catalina.base}/webapps/your_app_name/-" {
  permission java.security.AllPermission;  
};

```

### Build a new image

Available build args:
* **VERSION:** Default value: 9.0.41 (also tested with 10.0.0)
* **DEFAULT_JRE_PKG:** default-jdk
* **PORT_HTTP:**: Define the container HTTP port (-1 or omit
 to disable http. This is default)
* **PORT_SSL:** Defines the container HTTPS port (Default 8443)
* **TOMCAT_SERVICE_USR_NAME:** Defines the username for service user (default: tomcat)
* **TOMCAT_SERVICE_USR_UID:** Defines the UID for the service user (default: 997)
* **DBUG_PORT:** Define the container HTTP DEBUG port (-1 or omit
 to disable debugging options. This is default)

#### Examples

To build an Tomcat v9.0.41 with tefault options:
```
root@host:# docker build -t MyNewTomcatImage .
``` 

To build an Tomcat v9.0.41 with HTTP enabled in port 8080 and Debug options enabled in port 8000:

```
root@host:# docker build \ 
              --build-arg PORT_HTTP=8080 \
              --build-arg DBUG_PORT=8000 \ 
              -t MyNewTomcatImage .
``` 

To build an Tomcat **v10.0.0** with HTTP enabled in port 8080, Debug options enabled in port 8000 and SSL port in 8444:

```
root@host:# docker build \ 
              --build-arg PORT_HTTP=8080 \
              --build-arg DBUG_PORT=8000 \
              --build-arg PORT_SSL=8444 \ 
              -t MyNewTomcatImage .
``` 



