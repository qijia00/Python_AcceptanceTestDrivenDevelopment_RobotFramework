*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   LUM-1112   master_pointing   useless_script

*** Test Cases ***
Bring Master ECU into Site
    Connect to web services   ${IP}
    run keyword and ignore error   Login   ${user}   ${def_pass}
    run keyword and ignore error   Login   ${user}   ${pass}
    run keyword and ignore error   Remove from site
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    Logout

Bring Slave ECU into Site
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in this test case

    Connect to web services   ${slave_IP}
    run keyword and ignore error   Login   ${user}   ${def_pass}
    run keyword and ignore error   Login   ${user}   ${pass}
    run keyword and ignore error   Remove from site
    Bring ECU into site   ${IP}   ecu_name=SlaveECU   site_type=${site_type}   offset=OFFSET0
    #Note that once bring-into-site is called for a slave ECU, you will need to log out and log back in again,
    #since the authentication will now be based on the master-forwarding mechanism.
    logout
    Login   ${user}   ${pass}
    Get version
    logout

Modify TBL_ECU in the site database
    #you will need this test case/step to make master ECU strart posting master-info
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Get database information
    ${update_id}=   get update id
    Update tables   site_index=SITE0   json_payload=${tbl}   update_id=${update_id}   lock_id=
    logout

    Connect to web services   ${slave_IP}
    Login   ${user}   ${pass}
    Get version
    logout

Test Post Master Info
# for POST master-ip, it can't be called on the master neither on slave
# so this script is useless, the way to test POST master-ip is once you done with above steps
# from master ECU 9119 port listen in Spy, periodically you will see
# POST master-info messages automatically send from master to all slaves
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Get database information
    # Setting 'master-ecu-ip' is not allowed on master ECU!
    Set Master Info   json_payload=${master_info}   site_index=SITE0
    Logout

    connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    # Sending logout request to master ECU failed! since Clients should not be using POST master-info
    Set Master Info   json_payload=${master_info}   site_index=SITE0
    Logout


*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.101
${slave_IP}   172.24.172.102
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

${tbl}      SEPARATOR=\n
...   {
...       "update-id" : "",
...       "lock-id": "",
...       "add": [
...           {
...               "ecu": [
...                 {"IDENTIFIER": "11111111-1111-1111-1111-111111111111", "IP_ADDRESS": "${IP}"},
...                 {"IDENTIFIER": "33333333-3333-3333-3333-333333333333", "IP_ADDRESS": "${slave_IP}"}
...                ]
...           }
...       ]
...   }

${master_info}   SEPARATOR=\n
...   {
...      "master-ecu-ip": "${IP}",
...      "site-id" : ""
...  }

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
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Logout

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
    Remove File   .//artifacts//*.zip
    Remove File   .//artifacts//*.sqlite