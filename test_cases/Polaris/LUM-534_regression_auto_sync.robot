*** Settings ***
Library         PolarisLibrary
Library         WebServiceLibrary
Library         BuiltIn
Library         OperatingSystem

Suite Setup     Setup Polaris
Suite Teardown  Run keyword and ignore error   Cleanup ECU for next test

Documentation   Polaris regression check to test the auto sync


*** Variables ***
${IP}   172.24.172.141
${pass}   123456
${site_name}   RobotTestSite
${temp_site}   TempSite
${manager_area}   MyArea
${profile}   Class Room 1
${url}   http://localhost:9999
${driver}   win7

*** Keywords ***
Setup Polaris
    [Documentation]   Setups up Polaris by removing isolated storage, launching Polaris and monitoring its performance

    Remove File   .//input/*.*
    Remove Isolated Storage
    Launch Polaris

    ${status}   ${value}=   run keyword and ignore error   Connect to web services   ${IP}  sysadmin   ${pass}
    run keyword if  '${status}' == 'PASS'
    ...   Cleanup webservices

Launch Polaris

    Connect to polaris   url=${url}   driver=${driver}   wait=10
    Maximize application


Close Polaris
    Disconnect from Polaris


Cleanup webservices
    [Documentation]   Designed to clean up webservice artifacts and to go back to a clean system

    Connect to web services   ${IP}  sysadmin   ${pass}
    run keyword and ignore error   WebServiceLibrary.remove from site
    Delete site with id   SITE0
    WebServiceLibrary.logout

Cleanup ECU for next test
    [Documentation]   Ensures graceful exits of Polaris and wipes the ECU for the next test

    Disconnect from polaris
    Cleanup webservices

*** Test Cases ***
Create new temporary offline site
    [Documentation]   Create new site for restore system simulation
    PolarisLibrary.Create New Site   sitename=${temp_site}    password=${pass}   customer=Osram   project=osram_project   author=Alex
    PolarisLibrary.Logout

Create new Offline site
    [Documentation]   Create new site from Home - Working Offline - [Create New Site]
    PolarisLibrary.Create New Site   sitename=${site_name}   password=${pass}   customer=Osram   project=osram_project   author=Vidhya

Backup System
    [Documentation]   After you create a new offline site and logged into the site, export the site
    Backup system   path=.\\input\\${site_name}.zip
    PolarisLibrary.Logout

Activate System
    Load offline site   site=${site_name}
    Activate system   ip_addr=${IP}   password=${pass}

Land in Connect to Live system page
    [Documentation]  When there are both live system and local system available, it should land on the Connect
    ...              to Live System page

    Close Polaris
    Launch Polaris
    Find ui by id   login

Login with Sysadmin Password
    PolarisLibrary.login    sysadmin   ${pass}   ${IP}

Manager Area and Class Room Profile Creation
    Rename control area   ${manager_area}
    Create profile   Class Room   ${manager_area}

ECU and Device Mapping
    Identify ECU   ${IP}
    Map ECU   ${IP}   ${manager_area}

Reboot ECU
    [Documentation]   Reboot the Ecu so that it sleeps for 1 minute
    connect to web services  ${IP}  sysadmin   ${pass}
    WebServiceLibrary.reboot ecu

Add a few profiles
    [Documentation]   when the ecu is rebooting add a Lobby proifle and washroom profile to the control area
    ...               sleep for  a minute for the system to reboot
    Create profile   Lobby  ${manager_area}   L1
    Create profile   Class Room   ${manager_area}   C1

Search for the newly added profile
   [Documentation]   Search for the profile that is added when the ecu was rebooting to see if it has sync
   search profile   L1
   search profile   C1


Logout
    PolarisLibrary.logout