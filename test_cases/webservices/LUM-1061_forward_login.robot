*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   LUM-1061   forward_login

*** Test Cases ***
Forward login logout to master with site username and password
    clean sessions
    Connect to web services   ${IP}   db_read=false
    Login   ${user}   ${pass}   # SESSION0 is returned
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}   # SESSION1 is returned
    Get version    SESSION0
    Get version   SESSION1
    Connect to web services   ${IP}
    Get database information   SESSION0
    Get database information   SESSION1
    Connect to web services   ${slave_IP}
    logout
    Connect to web services   ${IP}
    Get database information   SESSION0
    run keyword and expect error   *   Get database information   SESSION1

Forward login logout to master with newly created username and password
    Add user   ${new_user}   SESSION0
    Connect to web services   ${slave_IP}    ${new_user_name}   ${new_user_password}   ${version}   # SESSION2 is returned
    run keyword and expect error   *   Add user   ${new_user2}
    Get version    SESSION0
    Get version   SESSION2
    Connect to web services   ${IP}
    Get database information   SESSION0
    Get database information   SESSION2
    Connect to web services   ${IP}
    logout
    Connect to web services   ${slave_IP}
    run keyword and expect error   *   Get version   SESSION0
    Get version   SESSION2

#Forward login logout to master when master is offline
#    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   10.215.21.121
${slave_IP}   10.215.23.97
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   12345
${new_user_name}   New Admin
${new_user_password}   54321
${new_user_name2}   New Admin2
${new_user_password2}   54321

${new_site}   SEPARATOR=\n
...     {
...         "name": "Site management test",
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

${new_user}   SEPARATOR=\n
...   {
...       "user-id": "",
...       "user-name": "${new_user_name}",
...       "user-group": 4,
...       "password-plaintext" : "${new_user_password}"
...   }

${new_user2}   SEPARATOR=\n
...   {
...       "user-id": "",
...       "user-name": "${new_user_name2}",
...       "user-group": 4,
...       "password-plaintext" : "${new_user_password2}"
...   }

*** Keywords ***
Setup System
#Create a cfg.json file under non-master ECU /firmware/webservice/data/cfg.json to indicate who is the master ECU:
#
#{
#    "master-ip" : "10.215.21.121"
#}
#
#Eventually, the cfg.json file will be created by Polaris to indicate who is the master ECU.
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout

Breakdown System
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.sqlite