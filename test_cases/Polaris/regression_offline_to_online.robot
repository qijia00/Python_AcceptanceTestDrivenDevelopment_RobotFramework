*** Settings ***
Library          PolarisLibrary
Library          WebServiceLibrary
Library          BuiltIn
Library          OperatingSystem
Suite Setup      Setup Polaris
Suite Teardown   Run keyword and ignore error   Cleanup Polaris

Force Tags      polaris   regression

*** Variables ***
${pass}   newpassword
${IP}   10.215.23.87

*** Keywords ***
Setup Polaris
    Remove File   .//input/*.*
    Remove Isolated Storage

    Connect to polaris  url=http://localhost:9999
    Maximize application

Cleanup Polaris
    Disconnect from polaris
    Remove File   .//input/*.*
   [Documentation]   Delete the site
    connect to web services  ${IP}   sysadmin   ${pass}
    Delete site with id   SITE0
    WebServiceLibrary.logout

*** Test Cases ***
Create Offline Site
    # Create new site from Home - Working Offline - [Create New Site]
    PolarisLibrary.Create New Site   sitename=OfflineSiteX   password=${pass}   customer=Osram   project=osram_project   author=Vidhya

Add user and Synchronize
    PolarisLibrary.add user   Basic One   basic1   ${pass}   Basic User   basic1@one.com

# Following lines are deprecated workflow
#Export Offline Site
#    # After you create a new offline site,you are logged into the site,Now I export
#    Export offline site   site=OfflineSiteX   path=.\\input\\OfflineSiteXExport.zip
#
#Restore System Snapshot
#    Restore system snapshot   .\\input\\OfflineSiteXExport.zip   ${IP}

Activate System
    Polaris.Activate system   ip_addr=${IP}   password=${pass}

Login with new Password
    PolarisLibrary.login    basic1   ${pass}   ${IP}
    PolarisLibrary.logout

Login with Default Password
    Run keyword and expect error   *  PolarisLibrary.login   sysadmin   1um3nad3   ${IP}

Delete All Added Users
    PolarisLibrary.login    sysadmin   ${pass}   ${IP}
    PolarisLibrary.remove user   basic1
    PolarisLibrary.logout