*** Settings ***
Library         PolarisLibrary
Library         WebServiceLibrary
Library         BuiltIn
Library         OperatingSystem
Suite Setup     Setup Polaris
Suite Teardown  Run keyword and ignore error   Cleanup ECU for next test

Force Tags      polaris   regression

Documentation   User management test

Metadata        Version      0.10

# TO DO:
# User password management

*** Variables ***
${IP}   10.215.23.88
${pass}   3nc31ium

*** Keywords ***
Setup Polaris
    Remove File   .//input/*.*
    Remove Isolated Storage

    Connect to polaris  url=http://localhost:9999
    Maximize application
    Monitor Performance
    ${status}   ${value}=   run keyword and ignore error   Connect to web services   ${IP}  sysadmin   ${pass}
    run keyword if  '${status}' == 'PASS'
    ...   Cleanup webservices

    Create new site

Cleanup webservices
    run keyword and ignore error   WebServiceLibrary.remove from site
    Delete site with id   SITE0
    WebServiceLibrary.logout

Cleanup ECU for next test
    Stop monitor performance
    Plot performance
    Disconnect from polaris
    Remove File   .//input/*.*
    Connect to web services   ${IP}  sysadmin   ${pass}
    Cleanup webservices

Create new site
    PolarisLibrary.Create New Site   sitename=OfflineSiteX   password=${pass}   customer=Osram   project=osram_project   author=Vidhya
    Activate system   ip_addr=${IP}   password=${pass}


*** Test Cases ***
Admnistrator Login
    PolarisLibrary.login  sysadmin   ${pass}   ${IP}

Add Basic Users
    PolarisLibrary.add user   Basic One   basic1   111111   # Basic User   basic1@one.com
    PolarisLibrary.add user   Basic Two   basic2   222222   # Basic User   basic2@one.com
    PolarisLibrary.add user   Basic Three   basic3   333333   # Basic User   basic3@one.com

    PolarisLibrary.logout

Validate Basic User Access
    PolarisLibrary.login   basic1   111111   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   basic2   222222   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   basic3   333333   ${IP}
    PolarisLibrary.logout

Delete All Added Users
    PolarisLibrary.login   sysadmin   ${pass}   ${IP}
    PolarisLibrary.remove user   basic1
    PolarisLibrary.remove user   basic2
    PolarisLibrary.remove user   basic3

    PolarisLibrary.logout