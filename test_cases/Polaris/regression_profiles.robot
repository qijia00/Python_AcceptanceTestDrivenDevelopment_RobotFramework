*** Settings ***
Library          PolarisLibrary
Library          WebServiceLibrary
Library          BuiltIn
Library          OperatingSystem
Suite Setup      Setup Polaris
Suite Teardown   Run keyword and ignore error   Cleanup ECU for next test

Force Tags      polaris   regression

*** Variables ***
${pass}   newpassword
${IP}   10.215.23.87
${site_name}   RobotTestSite

*** Keywords ***
Setup Polaris
    [Documentation]   Setups up Polaris by removing isolated storage, launching Polaris and monitoring its performance

    Remove File   .//output/*.*
    Remove Isolated Storage
    Launch Polaris

    ${status}   ${value}=   run keyword and ignore error   Connect to web services   ${IP}  sysadmin   ${pass}
    run keyword if  '${status}' == 'PASS'
    ...   Cleanup webservices

Launch Polaris
    Connect to polaris   url=http://localhost:9999   driver=win7   wait=2
    Maximize application
    #Monitor Performance

Cleanup Polaris
    Disconnect from Polaris
    #Stop monitor performance

Cleanup webservices
    [Documentation]   Designed to clean up webservice artifacts and to go back to a clean system

    Connect to web services   ${IP}  sysadmin   ${pass}
    run keyword and ignore error   WebServiceLibrary.remove from site
    Delete site with id   SITE0
    WebServiceLibrary.logout

Cleanup ECU for next test
    [Documentation]   Ensures graceful exits of Polaris and wipes the ECU for the next test
    Disconnect from polaris

    ${status}   ${value}=   run keyword and ignore error   Connect to web services   ${IP}  sysadmin   ${pass}
    run keyword if  '${status}' == 'PASS'
    ...   Cleanup webservices

*** Test Cases ***
Create new offline site
    [Documentation]   Create new site from Home - Working Offline - [Create New Site]
    PolarisLibrary.Create New Site   sitename=${site_name}   password=${pass}   customer=Osram   project=osram_project   author=Vidhya

Create new control areas
    [Documentation]   Creates a new control area
    Create profile   Single Office (A)   CONTROL0
    Create profile   Single Office (M)   CONTROL0

    Create control area
    Create profile   Multi Desk (A)   CONTROL1
    Create profile   Multi Desk (M)   CONTROL1
    Create profile   Open Office      CONTROL1

    Create control area
    Create profile   Meeting Room        CONTROL2
    Create profile   Corridor / Stairs   CONTROL2

    Create control area
    Create profile   Lobby      CONTROL3
    Create profile   Washroom   CONTROL3

    Create control area
    Create profile   Class Room        CONTROL4
    Create profile   Conference Room   CONTROL4

    Create control area
    Create profile   Canteen   CONTROL5

#Create profiles
#    [Documentation]   Creates a profile area in a specified control area
#    Create profile   Single Office (A)   CONTROL0
#    Create profile   Single Office (M)   CONTROL0
#
#    Create profile   Multi Desk (A)   CONTROL1
#    Create profile   Multi Desk (M)   CONTROL1
#    Create profile   Open Office      CONTROL1
#
#    Create profile   Meeting Room        CONTROL2
#    Create profile   Corridor / Stairs   CONTROL2
#
#    Create profile   Lobby      CONTROL3
#    Create profile   Washroom   CONTROL3
#
#    Create profile   Class Room        CONTROL4
#    Create profile   Conference Room   CONTROL4
#
#    Create profile   Canteen   CONTROL5

    PolarisLibrary.Logout


