*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System
Test Teardown    extract spy messages

Force Tags       webservices   LUM-3081   upgrade

*** Test Cases ***
Add/Map nodes to the System
    # Write Nodes to WhiteList
    Add node to polaris whitelist   ${prop_whiteListFromPolaris_input}
    #TODO Add Power off/on Z2D to trigger the search for WM. Sleep 5s for it to be up
    sleep   25s

    # battery device has to join by Mapping Tool via 3 steps
    # step 1, change ECU channel away from channel 26:
    Change Channel   extendedPanId=${extendedPanId}
    # the above line write to ECU Shark Target: 0032 -- ZigBee_NetworkManager, Index: 103 -- prop_zigbeeNetworkParams
    # after the write, you suppose to see Rodio Channel is 11, channel mask is 00000800, and Link Key Index is 0
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    ${prop_zigbeeNetworkParams}=   Read Property Access   target=${NetworkManager_address_hex}   index=103
    log   ${prop_zigbeeNetworkParams}
    # step 2, write 3 (OpenTemporarily) to Shark Target: ZigBee_NetworkManager, Index: prop_zigbeeNetworkSecurityMode
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    Write Property Access   target=${NetworkManager_address_hex}   index=24   value=[3]  access==   data_type=ZigBeeNetworkSecurityMode
    Disconnect
    Extract spy messages
    # step 3, join via mapping tool.
    connect to ECU   ${mapping_tool_IP}
    Join Via Mapping Tool      eui64=${sensor1}   extendedPanId=${extendedPanId}   linkKeyIndex=${linkKeyIndex}
    # the above line write to Mapping Tool Shark Target: 0033 -- ZigBee_DeviceScanner, Index: 102 -- prop_joinNetwork
    # but we do not know the input format, so we can not do in shark
    ${DeviceScanner_address_int}   ${DeviceScanner_address_hex}=   Get Object Address   0x0033
    ${prop_joinNetwork}=   Read Property Access   target=${DeviceScanner_address_hex}   index=102
    log   ${prop_joinNetwork}   # you suppose to see the eui64 id in the returns.
    sleep   25s
    Disconnect

    # read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that are mapped to this ECU.
    Connect to ECU   ${IP}   ${ecu_type}   spy_port=9110
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length}>0   No device is mapped to the ECU

Downgrade Z2D Converter
    Establish SSH connection   ${IP}
    Upload file   ${OTA_LOC_PATH}${OTA_FILE}   /firmware/upgrade/${OTA_FILE}
    # We downgrade all, so no need to add nodes, timeout higher due to the fact that nodes are upgraded one after the other
    OTA upgrade   policy=downgrade   timeout=600
    Verify z2d fw version   ${OTA_REV}   ${Node_Nr}

Upgrade Nodes including not available nodes
    sleep   5s   # After 5s of the last upgrade, the Status will be moved to Idle
    run keyword and expect error   *   Upgrade node fw   ${upgrade_nodes_not_available}  timeout=800

Upgrade All Nodes
    sleep   5s   # After 5s of the last upgrade, the Status will be moved to Idle
    Upgrade node fw   ${upgrade_all_nodes}   timeout=2000  # 3 nodes with about 10min each

Downgrade Z2D Nodes
    sleep   5s   # After 5s of the last upgrade, the Status will be moved to Idle
    Upgrade node fw   ${downgrade_z2d_nodes}   timeout=2000  # 3 nodes with about 10min each

Transgrade Sensor Nodes
    sleep   5s   # After 5s of the last upgrade, the Status will be moved to Idle
    Upgrade node fw   ${transgrade_sensor}   timeout=2000  # 3 nodes with about 10min each


*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.101
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   123456
${ecu_type}   WM

${z2d1}   000D6F000D84AC1C
${z2d1_URI}   ZigBee://${z2d1}.00
${z2d2}   000D6F000D84AE52
${z2d2_URI}   ZigBee://${z2d2}.00
${sensor1}   000D6F000D6B61B4
${sensor1_URI}   ZigBee://${sensor1}.00

${mapping_tool_IP}   127.0.0.1

# you can verbalize ECU Shark 0032 to get the following input
${extendedPanId}   0x000D6F000310BAA0
${linkKeyIndex}   255

${prop_whiteListFromPolaris_input}   SEPARATOR=\n
...     {
...         "Devices": [
...             {
...                 "Eui64": "${z2d1}"
...             },
...             {
...                 "Eui64": "${z2d2}"
...             },
...             {
...                 "Eui64": "${sensor1}"
...             }
...         ]
...     }

${upgrade_all_nodes}   SEPARATOR=\n
...     {
...         "Nodes": [
...             {"URI": "${z2d1_URI}"},
...             {"URI": "${z2d2_URI}"},
...             {"URI": "${sensor1_URI}"}
...         ],
...         "Policy": "Upgrade"
...     }

${upgrade_nodes_not_available}   SEPARATOR=\n
...     {
...         "Nodes": [
...             {"URI": "ZigBee://000D6F000D6B61B6.00"},
...             {"URI": "${sensor1_URI}"}
...         ],
...         "Policy": "Upgrade"
...     }

${transgrade_sensor}   SEPARATOR=\n
...     {
...         "Nodes": [
...             {"URI": "${sensor1_URI}"}
...         ],
...         "Policy": "Transgrade"
...     }

${downgrade_z2d_nodes}   SEPARATOR=\n
...     {
...         "Nodes": [
...             {"URI": "${z2d1_URI}"},
...             {"URI": "${z2d2_URI}"}
...         ],
...         "Policy": "Downgrade"
...     }


${OTA_LOC_PATH}     C:\\Users\\a.viaestrem\\Downloads\\
${OTA_FILE}         ZigbeeHaLightEndDevice0010.ota
${OTA_REV}          1071619  # This translates to 0x00105a03 = 0.0.1.0 (application) 5.10.0.3 (stack)
${NODES}            ""   # or empty or [000D6F000D84B2D6.00, 000D6F000D84B2D6.01]
${Node_Nr}          0

#${new_site}   SEPARATOR=\n
#...     {
#...         "name": "Site management test",
#...         "version": "Version 4.0.0",
#...         "customer": "QA",
#...         "project": "Robot",
#...         "author": "Angels",
#...         "default": true,
#...         "date": "06/29/2017 9:54:00 AM",
#...         "username": "${user}",
#...         "password": "${pass}",
#...         "fullname": "System Administrator",
#...         "site-type": "${site_type}"
#...     }


*** Keywords ***
Setup System
    run keyword if   $ecu_type == 'Dali'   Fail   Dali ECU not supported in this Test
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Connect to ECU   ${IP}   ${ecu_type}   spy_port=9110
    clean sessions
    Connect to web services   ${IP}
    Login   ${user}   ${def_pass}
#    Create new site   ${new_site}
#    Logout
#    Login   ${user}   ${pass}
#    Get database information
#    Bring ECU into site   ${IP}   ecu_name=MasterECU   site_type=${site_type}


Breakdown System
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Logout
    Disconnect
