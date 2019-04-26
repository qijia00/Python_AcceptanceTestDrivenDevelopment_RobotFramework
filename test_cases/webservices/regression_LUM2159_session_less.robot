*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   LUM-2159   session_less

*** Test Cases ***
# local-network session less is tested in regression_LUM202_change_ECU_ip.robot
# factory reset session less is tested in sanity_factory_reset.robot
# restore ecu session less is tested in sanity_backup_restore.robot
# reboot, version, create-site are tested here
Session id is not needed for reboot and version api if ECU has no site
    clean sessions
    connect to web services   ${IP}
    Reboot ECU
    Get version

Session id is not needed for create site api for a blank ECU
    clean sessions
    Connect to web services   ${IP}
    Create new site   ${new_site}

Session id is not needed for reboot and version api if ECU is out of site
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and expect error   *   Create new site   ${new_site}
    clean sessions
    Reboot ECU
    Get version

Bring ECU to site
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    Logout

Session id is needed for reboot but not needed for version api when ECU is part of site
    clean sessions
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Reboot ECU   session_index=SESSION0
    clean sessions
    Get version

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.102
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

*** Keywords ***
Setup System
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0

Breakdown System
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.sqlite