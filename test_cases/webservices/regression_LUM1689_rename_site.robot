*** Settings ***
Library          WebServiceLibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   LUM-1689   rename_site

*** Test Cases ***
# the database name will always be Site.sqlit
# the database-name from TBL_DB_INFO will be changed by Rename Site api

Change offline site name to valid name
    Connect to web services   ${IP}   dll=${offline_dll}   dll_data=${offline_storage}
    Login   ${user}   ${pass}
    Get Database Information   expected_site_name=${site_original}
    Rename Site   ${site_offline_name}   SITE0
    Get Database Information   expected_site_name=${site_offline}
    Logout

Change offline site name to a name with special charactors
    Connect to web services   ${IP}   dll=${offline_dll}   dll_data=${offline_storage}
    Login   ${user}   ${pass}
    Get Database Information   expected_site_name=${site_offline}
    Rename Site   ${site_special_charactor_name}   SITE0
    Get Database Information   expected_site_name=${site_special_charactor}
    Logout
    Disconnect from web services

Change online site name to valid name
    Connect to web services   ${IP}
    Login   ${user}   ${pass}
    Get Database Information   expected_site_name=${site_original}
    Rename Site   ${site_online_name}   SITE0
    Get Database Information   expected_site_name=${site_online}
    Logout

Change online site name to a name with special charactors
    Connect to web services   ${IP}
    Login   ${user}   ${pass}
    Get Database Information   expected_site_name=${site_online}
    Rename Site   ${site_special_charactor_name}   SITE0
    Get Database Information   expected_site_name=${site_special_charactor}
    Logout
    Disconnect from web services

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.101
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   12345
${site_original}   Rename site test
${site_online}   Online Site Name
${site_online_name}   SEPARATOR=\n
...   {
...       "site-name" : "Online Site Name"
...   }
${site_offline}   Offline Site Name
${site_offline_name}   SEPARATOR=\n
...   {
...       "site-name" : "Offline Site Name"
...   }
# to test \, you need to escape 2 times, which means \\\ will output \
# to test ", you need to escape once, which means \" will output "
${site_special_charactor}   `~!@#$%^&*()_+=-{}|[]\\\:\";'<>?,./
# to test \, you need to escape 3 times, which means \\\\ will output \
# to test ", you need to escape 3 times, which means \\\" will output "
${site_special_charactor_name}   SEPARATOR=\n
...   {
...       "site-name" : "`~!@#$%^&*()_+=-{}|[]\\\\:\\\";'<>?,./"
...   }

${new_site}   SEPARATOR=\n
...     {
...         "name": "${site_original}",
...         "version": "Version 4.0.0",
...         "customer": "QA",
...         "project": "Robot",
...         "author": "Jia",
...         "default": true,
...         "date": "06/29/2017 9:54:00 AM",
...         "username": "${user}",
...         "password": "${pass}",
...         "fullname": "System Administrator",
...         "site-type": "${site_type}"
...     }

${offline_dll}   .//artifacts//DataServiceDLL.dll
${offline_storage}   .//artifacts//testdata

*** Keywords ***
Setup System
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Logout
    Disconnect from web services
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    Logout
    Disconnect from web services

Breakdown System
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Disconnect from web services
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Run keyword and ignore error   Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Disconnect from web services
    Remove File   .//artifacts//*.sqlite
    Remove File   .//artifacts//testdata//data//*.json
    Remove File   .//artifacts//testdata//data//db//*.sqlite