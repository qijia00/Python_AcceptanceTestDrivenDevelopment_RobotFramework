*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   LUM-2294   update_web_service

*** Test Cases ***
Obtain the current version of the ECU files
    Connect to web services   ${IP}
    clean sessions
    ecu version
    Connect to web services   ${slave_IP}
    clean sessions
    ecu version

Upgrade without login on blank ECU
    Connect to web services   ${IP}
    clean sessions
    upgrade   ${upgrade_zip}
    ecu version

Bing the blank ECU back to its original version through factory reset
    connect to web services   ${IP}
    Factory default ecu
    Connect to web services   ${default_ip}
    change local ip   json_payload=${original_master_IP}
    sleep   20s
    Connect to web services   ${IP}
    ${ip_return}=  get local ip   expected_ip=${IP}
    Log   next line will fail due to LUM-4542   WARN
    ecu version

Create site and Bring Master ECU to site
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Log   next line will fail due to LUM-4542   WARN
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in Setup System
    Logout

Bring Slave ECU to site
    Connect to web services   ${slave_IP}   ${user}   ${def_pass}
    Bring ECU into site   ${IP}   ecu_name=SlaveECU   site_type=${site_type}   offset=OFFSET0
    logout
    Login   ${user}   ${pass}
    logout

Login logout from Master and Slave ECUs for UpdateWebService
    Connect to web services   ${IP}
    Login   ${user}   ${pass}
    Logout
    ecu version   ${user}   ${pass}
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Logout
    ecu version   ${user}   ${pass}

Upgrade after login
    Connect to web services   ${IP}
    run keyword and expect error   *   upgrade   ${upgrade_zip}
    Connect to web services   ${slave_IP}
    run keyword and expect error   *   upgrade   ${upgrade_zip}

    Connect to web services   ${slave_IP}
    clean sessions
    upgrade Login   ${user}   ${pass}
    upgrade   ${upgrade_zip}   session_index=SESSION0
    upgrade logout
    ecu version   ${user}   ${pass}

    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Factory default ecu
    Connect to web services   ${default_ip}
    change local ip   json_payload=${original_slave_IP}
    sleep   20s
    Connect to web services   ${slave_IP}
    ${ip_return}=  get local ip   expected_ip=${slave_IP}
    ecu version   ${user}   ${def_pass}

    Connect to web services   ${IP}
    clean sessions
    upgrade Login   ${user}   ${pass}
    upgrade   ${upgrade_zip}   session_index=SESSION0
    upgrade logout
    ecu version   ${user}   ${pass}

    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Factory default ecu
    Connect to web services   ${default_ip}
    change local ip   json_payload=${original_master_IP}
    sleep   20s
    Connect to web services   ${IP}
    ${ip_return}=  get local ip   expected_ip=${IP}
    ecu version   ${user}   ${def_pass}

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.101
${slave_IP}   172.24.172.102
${default_ip}   172.24.172.200
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   12345

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

${upgrade_zip}   .//input//LUMENADE_WM_ECU_UPDATE_ZIP_137.zip

${original_master_IP}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": [],
...       "Address": "${IP}"
...   }

${original_slave_IP}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": [],
...       "Address": "${slave_IP}"
...   }

*** Keywords ***
Setup System
    Log   please run this test on you own network   WARN
    Log   please make sure ECU/firmware/factoryDefault contains the currect LinuxECU DataWebService UpdateWebService exes  WARN
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Logout
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0

Breakdown System
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Remove from site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.sqlite