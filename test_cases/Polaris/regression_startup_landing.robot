*** Settings ***
Documentation    Suite description
Library         PolarisLibrary
Library         WebServiceLibrary
Library         BuiltIn
Library         OperatingSystem

Suite Setup     Setup Polaris
Suite Teardown  Run keyword and ignore error   Cleanup ECU for next test

Force Tags      polaris   regression

*** Test Cases ***
No System found Land in Create New System
   [Documentation]  When there are no local sites and no Live sites available,it should land on the Create Newsystem page
   ...              For this test ,make sure that there are no Live systems available at the beginning of the test
   find ui by id   new site create

Create offline system
   PolarisLibrary.create new site  sitename=${sn1}  password=${pass}
   PolarisLibrary.logout
   Disconnect from polaris

Only offline system found Land in open system page
   [Documentation]  When there are no live system and only local system available,it should land on the Open system page
   Connect to polaris   url=http://localhost:9999
   find ui by id   import local site

Load Offline System
   Load offline site   site=${sn1}

Deploy offline system to Live
   Restore system snapshot   .//input//offline_site2.zip   ${IP}
   Disconnect from polaris

Land in Connect to Live system page
   [Documentation]  When there are both live system and local system available,it should land on the Connect to Live System page
   Connect to polaris   url=http://localhost:9999
   find ui by id   login


*** Keywords ***
Setup Polaris
   #Remove File   .//input/*.*
   Remove Isolated storage
   Connect to polaris   url=http://localhost:9999

   ${status}   ${value}=   run keyword and ignore error   Connect to web services   ${IP}  sysadmin   ${pass}
    run keyword if  '${status}' == 'PASS'
    ...   Cleanup webservices

Cleanup webservices
    run keyword and ignore error   WebServiceLibrary.remove from site
    Delete site with id   SITE0
    WebServiceLibrary.logout

Cleanup ECU for next test
    Disconnect from polaris
    Connect to web services   ${IP}  sysadmin   ${pass}
    Cleanup webservices

*** Variables ***
${IP}   10.215.23.40
${pass}   123456
${sn1}   FirstofflineTest
