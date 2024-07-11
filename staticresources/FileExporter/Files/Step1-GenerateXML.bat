@ECHO off

:: this file expects to be handed the Data Loader bin directory as a parameter (%1).
PUSHD %1\bin

:: prompt for username and password
ECHO.
ECHO SET USERNAME AND PASSWORD
:getusername
SET Username=x
SET /P Username=                          Please enter username: 
IF %Username%==x GOTO :getusername
:getpassword
SET UnencryptedPassword=x
SET /P UnencryptedPassword=  Please enter password, without security token: 
IF %UnencryptedPassword%==x GOTO :getpassword
SET /P SecurityToken=         Please enter security token, if needed: 
SET EncryptedPasswordAndToken=

:: encrypt password
FOR /F "tokens=*" %%i in ('ENCRYPT -e %UnencryptedPassword%%SecurityToken%') do SET EncryptedPasswordAndToken=%%i

:: prompt user to choose endpoint
ECHO.
ECHO SET ENDPOINT
SET ChooseEndpoint=p
SET Endpoint=https://www.salesforce.com
SET /P ChooseEndpoint=  Do you want to use production (default) or sandbox? (p/s): 
IF %ChooseEndpoint%==s SET Endpoint=https://test.salesforce.com

:: prompt user for proxy settings
ECHO.
ECHO SET PROXY
SET ChooseProxy=n
SET ProxyHost=
SET ProxyPort=
SET ProxyUsername=
SET UnencryptedProxyPassword=x
SET EncryptedProxyPassword=
SET /P ChooseProxy=  Are you using a proxy server (default no)? (y/n): 
IF %ChooseProxy%==y SET /P ProxyHost=  Enter proxy server name: 
IF %ChooseProxy%==y SET /P ProxyPort=  Enter proxy server port: 
IF %ChooseProxy%==y SET /P ProxyUsername=  Enter proxy server username: 
IF %ChooseProxy%==y SET /P UnencryptedProxyPassword=  Enter proxy server password: 

:: encrypt proxy password
IF %ChooseProxy%==y IF NOT %UnencryptedProxyPassword%==x FOR /F "tokens=*" %%i in ('ENCRYPT -e %UnencryptedProxyPassword%') do SET EncryptedProxyPassword=%%i

:: return to previous directory
POPD

:: create process-conf.xml's DOCTYPE tag
ECHO ^<!DOCTYPE beans PUBLIC "-//SPRING//DTD BEAN//EN" "http://www.springframework.org/dtd/spring-beans.dtd" [> process-conf.xml
ECHO      ^<!ENTITY userName "%Username%"^>>> process-conf.xml
ECHO      ^<!ENTITY encryptedPassword "%EncryptedPasswordAndToken%"^>>> process-conf.xml
ECHO      ^<!ENTITY dir "%CD%"^>>> process-conf.xml
ECHO      ^<!ENTITY endpoint "%Endpoint%"^>>> process-conf.xml
ECHO      ^<!ENTITY proxyHost "%ProxyHost%"^>>> process-conf.xml
ECHO      ^<!ENTITY proxyPort "%ProxyPort%"^>>> process-conf.xml
ECHO      ^<!ENTITY proxyUsername "%ProxyUsername%"^>>> process-conf.xml
ECHO      ^<!ENTITY encryptedProxyPassword "%EncryptedProxyPassword%"^>>> process-conf.xml
ECHO ]^>>> process-conf.xml

:: add body to process-conf.xml
TYPE beans.xml >> process-conf.xml