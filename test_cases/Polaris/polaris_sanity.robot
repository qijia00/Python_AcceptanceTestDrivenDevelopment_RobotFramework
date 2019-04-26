*** Settings ***
Library         PolarisLibrary
Library         WebServiceLibrary
Library         BuiltIn
Library         OperatingSystem

Suite Setup     Setup Polaris
Suite Teardown  Run keyword and ignore error   Cleanup ECU for next test

Force Tags      polaris   sanity_test   smoke_test

Documentation   Polaris sanity check to test the basic and critical functionality of Polaris.

Metadata        Version      0.50
Metadata        Changelist   Jun 07, 2018
...                          - Removed startup procedures
...                          - Added online backup
...                          Jan 26, 2018
...                          - Removed Synchronization step, no longer needed w/ auto syncing
...                          Jan 10, 2018
...                          - Added monitor polaris performance during test
...                          - Added startup sequence state machine validation
...                          - Removed all user management test cases and keywords


*** Variables ***
${IP}   192.168.86.87
${pass}   12345678
${site_name}   RobotTestSite
${temp_site}   TempSite
${manager_area}   MyArea
${profile}   Class Room 1
${clm1}   000D6F0003EA730C.02
${url}   http://192.168.86.100:4723
${hubsense}   192.168.86.100
${driver}   win10mouse
${auth}   ('RobotAgent','3nc31ium')

*** Keywords ***
Setup Polaris
    [Documentation]   Setups up Polaris by removing isolated storage, launching Polaris and monitoring its performance

    Remove File   .//input/*.*
    Remove Isolated Storage   hostname=${hubsense}   auth=${auth}

    ${status}   ${value}=   run keyword and ignore error   Connect to web services   ${IP}  sysadmin   ${pass}
    run keyword if  '${status}' == 'PASS'
    ...   Cleanup webservices

    Launch Polaris

Launch Polaris
    Connect to polaris   url=${url}   driver=${driver}   auth=${auth}   wait=2
    Maximize application
    Monitor Performance

Close Polaris
    Disconnect from Polaris
    Stop monitor performance

Cleanup webservices
    [Documentation]   Designed to clean up webservice artifacts and to go back to a clean system

    Connect to web services   ${IP}  sysadmin   ${pass}
    run keyword and ignore error   WebServiceLibrary.remove from site
    Delete site with id   SITE0
    WebServiceLibrary.logout

Cleanup ECU for next test
    [Documentation]   Ensures graceful exits of Polaris and wipes the ECU for the next test

    Stop monitor performance
    Plot performance
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

Backup Offline System
    [Documentation]   After you create a new offline site and logged into the site, export the site
    Backup system   path=.\\input\\${site_name}.zip
    PolarisLibrary.Logout

Delete System
    Delete offline system   ${site_name}

Load Offline System
    [Documentation]   Load previosly created offline site
    Load offline site   site=${temp_site}
    PolarisLibrary.Logout

Import backup
    Import offline site   path=.\\input\\${site_name}.zip

Activate System
    Load offline site   site=${site_name}
    Activate system   ip_addr=${IP}   password=${pass}

Login with Default Password
    Run keyword and expect error   *  PolarisLibrary.login   sysadmin   1um3nad3   ${IP}

Login with Sysadmin Password
    PolarisLibrary.login    sysadmin   ${pass}   ${IP}

Manager Area and Class Room Profile Creation
    Rename control area   ${manager_area}
    Create profile   Class Room   ${manager_area}

ECU and Device Mapping
    Identify ECU   ${IP}
    Map ECU   ${IP}   ${manager_area}
    Map Node   ${clm1}   Teacher   ${profile}
    Close profile

Backup Online System
    Backup system   path=.\\input\\${site_name}_online.zip   timeout=120

Unmap Devices
    Unmap node   ${clm1}   ${profile}
    Remove node from network   ${clm1}
    Close profile

Profile Cleanup
    Delete profile   ${profile}

Logout
    PolarisLibrary.logout