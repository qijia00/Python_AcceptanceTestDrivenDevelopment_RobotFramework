*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem
Library          HWSupportLibrary

Suite Setup      Setup System
Suite Teardown   Breakdown System

Test Teardown    Extract Spy Messages

Force Tags       webservices   LUM-2452   unmap_ecu

*** Test Cases ***
Site/ECU Management Test - Bring Slave ECU into site
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Get database information
    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in this test case
    Logout
    Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Remove from site
    Bring ECU into site   ${IP}   ecu_name=SlaveECU   site_type=${site_type}   offset=OFFSET0
    Logout

#Site/ECU Management Test - Switch to Master ECU
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Free offsets   SITE0   {"offsets":${offsets_list}}
    Logout

Map a Fixture to Master ECU
    # please don't map devices before Setup System, otherwise all mapped devices will be unmapped when NVRam is removed
    connect to ECU   ${IP}
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_fixture_input}  access==   data_type=Dynarray
    sleep   30s
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length}>0   No fixture is mapped to the ECU
    Disconnect

Map a Keypad to Slave ECU
    # please don't map devices before Setup System, otherwise all mapped devices will be unmapped when NVRam is removed
    connect to ECU   ${slave_IP}
    Change Channel   extendedPanId=${extendedPanId}
    sleep   5s
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    Write Property Access   target=${NetworkManager_address_hex}   index=24   value=[(3)]  access==   data_type=ZigBeeNetworkSecurityMode
    sleep   5s
    Disconnect
    Connect to Relays   ${relay_port}
    activate momentary relay   ${relay_number}   delay=0.5
    disconnect from relays
    connect to ECU   ${mapping_tool_IP}
    Join Via Mapping Tool      eui64=${keypad}   extendedPanId=${extendedPanId}   linkKeyIndex=${linkKeyIndex}
    ${DeviceScanner_address_int}   ${DeviceScanner_address_hex}=   Get Object Address   0x0033
    ${prop_joinNetwork}=   Read Property Access   target=${DeviceScanner_address_hex}   index=102
    log   ${prop_joinNetwork}   # you suppose to see the eui64 id in the returns.
    sleep   30s
    Disconnect
    connect to ECU   ${slave_IP}
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length} > 0   No keypad is mapped to the ECU
    Disconnect

Site/ECU Management Test - Unmap Master ECU
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    #when ECU has been brought into site, then its offset will be no less than 100.
    ${original_ecu_offset}=   get ecu offset
    should be true   ${original_ecu_offset}>=100

    connect to ECU   ${IP}
    #read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that mapped to this ECU.
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length}>0   Please map devices to Master ECU before run the script

    # clear white list by write to Shark Target: ZigBee_NetworkManager, Index: prop_whiteListFromPolaris
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_empty_input}  access==   data_type=Dynarray

    unmap ecu

    #after unmap ecu, the ecu will be kept in site with same offset.
    ${current_ecu_offset}=   get ecu offset
    should be equal   ${original_ecu_offset}   ${current_ecu_offset}
    #after unmap ecu, all the mapped devices should be unmapped.
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length}==0

Site/ECU Management Test - Unmap Slave ECU
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    #when ECU has been brought into site, then its offset will be no less than 100.
    ${original_slave_ecu_offset}=   get ecu offset
    should be true   ${original_slave_ecu_offset}>=100

    connect to ECU   ${slave_IP}
    #read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that mapped to this ECU.
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length}>0   Please map devices to slave ECU before run the script

    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    get database information
    # wake keypad up by relay controller
    Connect to Relays   ${relay_port}
    activate momentary relay   ${relay_number}   delay=0.5
    disconnect from relays
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}

    unmap ecu

    #after unmap ecu, the ecu will be kept in site with same offset.
    ${current_slave_ecu_offset}=   get ecu offset
    should be equal   ${original_slave_ecu_offset}   ${current_slave_ecu_offset}
    #after unmap ecu, all the mapped devices should be unmapped.
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length}==0

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.101
${slave_IP}   172.24.172.102
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

${fixture}   000D6F000EBEE843
${prop_whiteListFromPolaris_fixture_input}   SEPARATOR=\n
...     {
...         "Devices": [
...             {
...                 "Eui64": "${fixture}"
...             }
...         ]
...     }
${prop_whiteListFromPolaris_empty_input}   SEPARATOR=\n
...     {
...         "Devices": []
...     }

# you can verbalize ECU Shark 0032 to get the following input
${extendedPanId}   0x000D6F0002F3ADE6
${linkKeyIndex}   255

# go to automated_mapping_x_x.robot for instrucitons on how to get the value of these
${relay_port}   COM10
${relay_number}   RELAY4

${mapping_tool_IP}   127.0.0.1
${keypad}   000D6F0010061F00



*** Keywords ***
Setup System
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU   site_type=${site_type}
    Logout

    Connect to ECU   ${IP}   spy_port=9119

Breakdown System
    [Documentation]   Remove the Master ECU from the site & Delete the site
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Run keyword and ignore error   Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.zip
    Remove File   .//artifacts//*.sqlite
    Disconnect
