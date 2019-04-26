*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   LUM-202   change_ECU_network_settings

*** Test Cases ***
Session id is not needed for local-network api when ECU is out of site
    clean sessions
    Connect to web services   ${IP}
    change local ip   ${new_master_IP}
    sleep   20s
    Connect to web services   ${IP_new}
    ${ip_return}=  get local ip   expected_ip=${IP_new}

Create site and Bring Master ECU to site
    Connect to web services   ${IP_new}   ${user}   ${def_pass}   ${version}
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${IP_new}   ecu_name=MasterECU
    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in Setup System
    Logout

Session id is needed for local-network api when ECU is part of site
    clean sessions
    Connect to web services   ${IP_new}   ${user}   ${pass}   ${version}
    change local ip   json_payload=${original_master_IP}   session_index=SESSION0
    sleep   20s
    Connect to web services   ${IP}
    ${ip_return}=  get local ip   expected_ip=${IP}

Bring Slave ECU to site
    Connect to web services   ${slave_IP}   ${user}   ${def_pass}
    Bring ECU into site   ${IP}   ecu_name=SlaveECU   site_type=${site_type}   offset=OFFSET0
    logout
    Login   ${user}   ${pass}
    logout

Change Master ECU IPs to valid values
    Connect to web services   ${IP}
    Login   ${user}   ${pass}
    change local ip   ${new_master_IP}
    sleep   20s
    Connect to web services   ${IP_new}
    ${ip_return}=  get local ip   expected_ip=${IP_new}

Change Master ECU IPs to invalid values
    Connect to web services   ${IP_new}
    Login   ${user}   ${pass}
    run keyword and expect error   *   change local ip   ${new_master_IP_invalid}
    sleep   5s
    ${ip_return}=  get local ip   expected_ip=${IP_new}
    Logout

Change Master ECU IPs back to original values
    Connect to web services   ${IP_new}
    Login   ${user}   ${pass}
    change local ip   json_payload=${original_master_IP}
    sleep   20s
    Connect to web services   ${IP}
    ${ip_return}=  get local ip   expected_ip=${IP}

Change Slave ECU IPs to valid values
    Connect to web services   ${slave_IP}
    Login   ${user}   ${pass}
    change local ip   ${new_slave_IP}
    sleep   20s
    Connect to web services   ${slave_IP_new}
    ${ip_return}=  get local ip   expected_ip=${slave_IP_new}

Change Slave ECU IPs to invalid values
    Connect to web services   ${slave_IP_new}
    Login   ${user}   ${pass}
    run keyword and expect error   *   change local ip   ${new_slave_IP_invalid}
    sleep   5s
    ${ip_return}=  get local ip   expected_ip=${slave_IP_new}
    Logout

Change Slave ECU IPs back to original values
    Connect to web services   ${slave_IP_new}
    Login   ${user}   ${pass}
    change local ip   ${original_slave_IP}
    sleep   20s
    Connect to web services   ${slave_IP}
    ${ip_return}=  get local ip   expected_ip=${slave_IP}

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.101
${IP_new}   172.24.172.103
${slave_IP}   172.24.172.102
${slave_IP_new}   172.24.172.104
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

${original_master_IP}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": [],
...       "Address": "${IP}"
...   }

${new_master_IP}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": [],
...       "Address": "${IP_new}"
...   }

${new_master_IP_invalid}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": ["172.24.172.1"],
...       "Address": "224.24.172.105"
...   }

${original_slave_IP}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": [],
...       "Address": "${slave_IP}"
...   }

${new_slave_IP}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": [],
...       "Address": "${slave_IP_new}"
...   }

${new_slave_IP_invalid}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": ["0.24.172.1"],
...       "Address": "${slave_IP}"
...   }

*** Keywords ***
Setup System
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
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.zip
    Remove File   .//artifacts//*.sqlite