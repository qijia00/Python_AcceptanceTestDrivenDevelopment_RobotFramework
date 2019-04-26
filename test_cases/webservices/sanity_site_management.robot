*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem
Library          Collections

Suite Setup      System Startup
Suite Teardown   System Breakdown
Test Teardown    Extract Spy Messages

Force Tags       webservices   regression

*** Test Cases ***
Site Management Test - Delete Site
    Comment   Delete the site created during test setup
    Login   ${user}   ${pass}
    Get database information
    Delete site with id   SITE0
    Run keyword and expect error   *   Login   ${user}   ${pass}
    Login   ${user}   ${def_pass}
    Logout

Site Management Test - Create Site & Bring Master ECU into site
    Comment   Create a new site & bring master ECU to site
    Login   ${user}   ${def_pass}
    Create new site   ${new_site}
    Logout
    Run keyword and expect error   *   Login   ${user}   ${def_pass}
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU   site_type=${site_type}
    Logout
    run keyword and expect error   *   delete site with id   SITE0

Site Management Test - Bring Slave ECU into site and Remove slave & master ECU from site
    Login   ${user}   ${pass}
    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in this test case
    Comment   Connect to a slave ecu to bring it into site then remove from site
    Connect to web services   ${slave_IP}
    Login   ${user}   ${def_pass}
    run keyword and ignore error   Remove from site
    Bring ECU into site   ${IP}   ecu_name=SlaveECU   site_type=${site_type}   offset=OFFSET0
    Remove from site
    Logout

    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Get database information
    Free offsets   SITE0   {"offsets":${offsets_list}}
    Remove from site
    Logout

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   192.168.86.88
${slave_IP}   192.168.86.89
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   newpassword
${default_ip}   172.24.172.200

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

*** Keywords ***
System Startup
    Run keyword and continue on failure   Reset System   ${IP}
    Run keyword and continue on failure   Reset System   ${slave_IP}

    Connect to ECU   ${IP}   spy_port=9119
    Connect to web services   ${IP}   ${user}   ${def_pass}

    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Logout

System Breakdown
    Extract Spy Messages
    Disconnect
    Run keyword and continue on failure   Reset System   ${IP}
    Run keyword and continue on failure   Reset System   ${slave_IP}

Reset System
    [Arguments]   ${ip}
    ${status}   ${value}=   run keyword and ignore error   Connect to web services   ${ip}   ${user}   ${pass}

    run keyword if  '${status}' == 'PASS'
    ...   Factory default with IP change   ${ip}

    Connect to web services   ${ip}   ${user}   ${def_pass}
    Factory default with IP change   ${ip}

    Connect to ECU   ${ip}
    Add public key
    Disconnect

Factory default with IP change
    [Arguments]   ${ip}
    Factory default ecu   timeout=120
    Connect to web services   ${default_ip}  timeout=120

    ${json}=   Evaluate   json.loads('''${original_master_IP}''')   json
    Set to dictionary   ${json}   Address=${ip}
    ${json_string}=   Evaluate   json.dumps(${json})   json

    Change local ip   json_payload=${json_string}
    Sleep   30
