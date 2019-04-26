*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   regression

*** Test Cases ***
Session id is not needed for factory reset api if ECU has no site
    clean sessions
    connect to web services   ${IP}
    Factory default ecu   timeout=60
    Connect to web services   ${default_ip}  timeout=240
    change local ip   json_payload=${original_master_IP}
    Connect to web services   ${IP}    timeout=240
    ${ip_return}=  get local ip   expected_ip=${IP}

Create a site
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Create new site   ${new_site}
    Logout

Session id is not needed for factory reset api if ECU is out of site
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    clean sessions
    Factory default ecu   timeout=60
    Connect to web services   ${default_ip}  timeout=240
    change local ip   json_payload=${original_master_IP}
    Connect to web services   ${IP}   timeout=240
    ${ip_return}=  get local ip   expected_ip=${IP}

Create a site & Bring ECU to site
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    Logout

Session id is needed for factory reset api when ECU is part of site
    clean sessions
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Factory default ecu   session_index=SESSION0   timeout=60
    clean sessions
    Connect to web services   ${default_ip}    timeout=240
    change local ip   json_payload=${original_master_IP}
    Connect to web services   ${IP}    timeout=240
    ${ip_return}=  get local ip   expected_ip=${IP}

#the following code works too
#ECU Mnagement Test - Factory reset part 1
#    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
#    Create new site   ${new_site}
#    Logout
#    Login   ${user}   ${pass}
#    Factory default ecu   timeout=360
#
#ECU Mnagement Test - Factory reset part 2
#    establish ssh connection   ${default_ip}   # please run this test on you own network
#    change encelium ip   ${IP}   255.255.252.0   10.215.20.1

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   192.168.86.88
${default_ip}   172.24.172.200
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   newpassword

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
Setup System
    Log   please run this test on you own network   WARN
    Log   the test suits need Image 70+ otherwise once factory reset the code will roll back to old code   WARN
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0

Breakdown System
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Logout
    Remove File   .//artifacts//*.sqlite