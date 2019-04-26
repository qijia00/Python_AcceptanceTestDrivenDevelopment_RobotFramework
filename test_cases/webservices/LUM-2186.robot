*** Settings ***
Library         WebServiceLibrary

Suite Setup     Connect to web services   10.215.23.87   sysadmin   1um3nad3
Suite Teardown  Disconnect from web services
Test Teardown   Test cleanup

*** Keywords ***
Test cleanup
    ${status}   ${value}=   run keyword and ignore error   Login   sysadmin   3nc31ium
    run keyword if  '${status}' == 'PASS'
    ...   Delete site with id   SITE0

*** Test Cases ***
Long term system restore cycle
    : For   ${index}   in range   1   5000
    \   Login   sysadmin   1um3nad3
    \   Restore site   .//input//feb12site.zip
    \   Comment   Site restore complete
    \   Login   sysadmin   3nc31ium
    \   Get database information
    \   Delete site with id   SITE0
    \   Comment   Site delete complete

Long term system restore cycle with remove site attempt
    : For   ${index}   in range   1   5000
    \   Login   sysadmin   1um3nad3
    \   Restore site   .//input//feb12site.zip
    \   Comment   Site restore complete
    \   Login   sysadmin   3nc31ium
    \   Get database information
    \   Run keyword and ignore error   Remove from site
    \   Delete site with id   SITE0
    \   Comment   Site delete complete

Long term system restore cycle without re-login
    : For   ${index}   in range   1   5000
    \   Login   sysadmin   1um3nad3
    \   Restore site   .//input//feb12site.zip
    \   Comment   Site restore complete
    \   Get database information
    \   Delete site with id   SITE0
    \   Comment   Site delete complete

Long term system restore cycle with remove site attempt without re-login
    : For   ${index}   in range   1   5000
    \   Login   sysadmin   1um3nad3
    \   Restore site   .//input//feb12site.zip
    \   Comment   Site restore complete
    \   Get database information
    \   Run keyword and ignore error   Remove from site
    \   Delete site with id   SITE0
    \   Comment   Site delete complete
