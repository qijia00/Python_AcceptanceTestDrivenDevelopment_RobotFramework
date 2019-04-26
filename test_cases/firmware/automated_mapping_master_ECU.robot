*** Settings ***
Library             ECULibrary
Library             WebServiceLibrary
Library             OperatingSystem
Library             BuiltIn
Library             String
Library             Collections
Library             HWSupportLibrary

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       firmware   automated-mapping

*** Test Cases ***
Map Fixture
    # powered device can join ECU via white list, but battery device can only join via mapping tool.
    connect to ECU   ${IP}
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    # write to Shark Target: ZigBee_NetworkManager, Index: prop_whiteListFromPolaris
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_fixture_input}  access==   data_type=Dynarray
    sleep   30s
    # read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that mapped to this ECU.
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length}>0   No fixture is mapped to the ECU
    Disconnect

    # turn ballast On then Off via Shark Target: ZigBee_EnceliumBallast, Index: 10 -- prop_dimLevel
    connect to ECU   ${IP}
    ${fixture1_ballast_endpoint_hex}=   Ballast Endpoint   eui64=${fixture1}
    Write Property Access   target=${fixture1_ballast_endpoint_hex}   index=10   value=1000   access==   data_type=Brightness
    Sleep   2s
    Write Property Access   target=${fixture1_ballast_endpoint_hex}   index=10   value=0   access==   data_type=Brightness
    Sleep   2s

    # clear white list by write to Shark Target: ZigBee_NetworkManager, Index: prop_whiteListFromPolaris
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_empty_input}  access==   data_type=Dynarray
    Disconnect

    # unmap all the notes from the ECU, you can call unmap ecu API, but your ECU needs to be in site.
    Connect to web services   ${IP}   ${user}   ${pass}
    unmap ecu   timeout=60
    # read from Shark Target: Zigbee_NetworkManager, Index: prop_nodetree for a list of devices that are mapped to the ECU.
    connect to ECU   ${IP}
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length}==0   Fixture is NOT unmapped from the ECU

    #disconnect from ECU
    Disconnect

Map Sensor
    # powered device can join ECU via white list, but battery device can only join via mapping tool after wake up.
    connect to ECU   ${IP}
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    # write to Shark Target: ZigBee_NetworkManager, Index: prop_whiteListFromPolaris
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_sensor_input}  access==   data_type=Dynarray
    sleep   30s
    # read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that mapped to this ECU.
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length_fixture}=   Evaluate   len($device_list)
    should be true   ${device_list_length_fixture} > 0   No fixture is mapped to the ECU

    # battery device has to join by Mapping Tool via 3 steps
    # step 1, change ECU channel away from channel 26:
    Change Channel   extendedPanId=${extendedPanId}
    # the above line write to ECU Shark Target: 0032 -- ZigBee_NetworkManager, Index: 103 -- prop_zigbeeNetworkParams
    # after the write, you suppose to see Rodio Channel is 11, channel mask is 00000800, and Link Key Index is 0
    sleep   5s

    # step 2, write 3 (OpenTemporarily) to Shark Target: ZigBee_NetworkManager, Index: prop_zigbeeNetworkSecurityMode
    Write Property Access   target=${NetworkManager_address_hex}   index=24   value=[(3)]  access==   data_type=ZigBeeNetworkSecurityMode
    sleep   5s
    Disconnect

    # step 3, join via mapping tool.
    # use the fixture as a flashlight to wake the sensor up (pysically place the fixture above the sensor)
    connect to ECU   ${IP}
    ${fixture2_ballast_endpoint_hex}=   Ballast Endpoint   eui64=${fixture2}
    # turn ballast On then Off via Shark Target: ZigBee_EnceliumBallast, Index: 10 -- prop_dimLevel
    Write Property Access   target=${fixture2_ballast_endpoint_hex}   index=10   value=0   access==   data_type=Brightness
    Sleep   2s
    Write Property Access   target=${fixture2_ballast_endpoint_hex}   index=10   value=1000   access==   data_type=Brightness
    Sleep   2s
    Write Property Access   target=${fixture2_ballast_endpoint_hex}   index=10   value=0   access==   data_type=Brightness
    Sleep   2s
    Disconnect
    # battery device has to join via mapping tool, white list won't work
    connect to ECU   ${mapping_tool_IP}
    Join Via Mapping Tool      eui64=${sensor}   extendedPanId=${extendedPanId}   linkKeyIndex=${linkKeyIndex}
    # the above line write to Mapping Tool Shark Target: 0033 -- ZigBee_DeviceScanner, Index: 102 -- prop_joinNetwork
    # but we do not know the input format, so we can not do in shark, we have to use join_via_mapping_tool funtion which based on ecu_test_tools.py
    ${DeviceScanner_address_int}   ${DeviceScanner_address_hex}=   Get Object Address   0x0033
    ${prop_joinNetwork}=   Read Property Access   target=${DeviceScanner_address_hex}   index=102
    log   ${prop_joinNetwork}   # you suppose to see the eui64 id in the returns.
    sleep   30s
    Disconnect

    # read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that mapped to this ECU.
    connect to ECU   ${IP}
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length_fixture_sensor}=   Evaluate   len($device_list)
    should be true   ${device_list_length_fixture_sensor} > ${device_list_length_fixture}   No sensor is mapped to the ECU

    # clear white list by write to Shark Target: ZigBee_NetworkManager, Index: prop_whiteListFromPolaris
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_empty_input}  access==   data_type=Dynarray

    # wake up the sensor
    Write Property Access   target=${fixture2_ballast_endpoint_hex}   index=10   value=0   access==   data_type=Brightness
    Sleep   2s
    Write Property Access   target=${fixture2_ballast_endpoint_hex}   index=10   value=1000   access==   data_type=Brightness
    Sleep   2s
    Write Property Access   target=${fixture2_ballast_endpoint_hex}   index=10   value=0   access==   data_type=Brightness
    Sleep   2s
    Disconnect

    # unmap all the notes from the ECU, you can call unmap ecu API, but your ECU needs to be in site.
    Connect to web services   ${IP}   ${user}   ${pass}
    unmap ecu   timeout=60
    # read from Shark Target: Zigbee_NetworkManager, Index: prop_nodetree for a list of devices that are mapped to the ECU.
    connect to ECU   ${IP}
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length_no_fixture_no_sensor}=   Evaluate   len($device_list)
    should be true   ${device_list_length_no_fixture_no_sensor} == 0   Fixture and sensor are NOT unmapped from the ECU
    Disconnect

Map Keypad
    # powered device can join ECU via white list, but battery device has to join by Mapping Tool via 3 steps after wake up.
    # step 1, change ECU channel away from channel 26:
    connect to ECU   ${IP}
    Change Channel   extendedPanId=${extendedPanId}
    # the above line write to ECU Shark Target: 0032 -- ZigBee_NetworkManager, Index: 103 -- prop_zigbeeNetworkParams
    # after the write, you suppose to see Rodio Channel is 11, channel mask is 00000800, and Link Key Index is 0
    sleep   5s
    Disconnect

    # step 2, write 3 (OpenTemporarily) to Shark Target: ZigBee_NetworkManager, Index: prop_zigbeeNetworkSecurityMode
    connect to ECU   ${IP}
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    Write Property Access   target=${NetworkManager_address_hex}   index=24   value=[(3)]  access==   data_type=ZigBeeNetworkSecurityMode
    sleep   5s
    Disconnect

    # step 3, wake the keypad up and join via mapping tool.
    Connect to Relays   ${relay_port}
    activate momentary relay   ${relay_number}   delay=0.5
    disconnect from relays

    connect to ECU   ${mapping_tool_IP}
    Join Via Mapping Tool      eui64=${keypad}   extendedPanId=${extendedPanId}   linkKeyIndex=${linkKeyIndex}
    # the above line write to Mapping Tool Shark Target: 0033 -- ZigBee_DeviceScanner, Index: 102 -- prop_joinNetwork
    # but we do not know the input format, so we can not do in shark, we have to use join_via_mapping_tool funtion which based on ecu_test_tools.py
    ${DeviceScanner_address_int}   ${DeviceScanner_address_hex}=   Get Object Address   0x0033
    ${prop_joinNetwork}=   Read Property Access   target=${DeviceScanner_address_hex}   index=102
    log   ${prop_joinNetwork}   # you suppose to see the eui64 id in the returns.
    sleep   30s
    Disconnect

    # read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that mapped to this ECU.
    connect to ECU   ${IP}
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length} > 0   No keypad is mapped to the ECU
    Disconnect

    # wake keypad up by relay controller
    Connect to Relays   ${relay_port}
    activate momentary relay   ${relay_number}   delay=0.5
    disconnect from relays
    # unmap all the notes from the ECU, you can call unmap ecu API, but your ECU needs to be in site.
    Connect to web services   ${IP}   ${user}   ${pass}
    unmap ecu   timeout=60
    # read from Shark Target: Zigbee_NetworkManager, Index: prop_nodetree for a list of devices that are mapped to the ECU.
    connect to ECU   ${IP}
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length} == 0   Keypad is NOT unmapped from the ECU
    Disconnect

*** Variables ***
${IP}   172.24.172.102
# you can verbalize ECU Shark 0032 to get the following input
${extendedPanId}   0x000D6F000D248B3E
${linkKeyIndex}   255
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
...         "site-type": "lumenade"
...     }

${mapping_tool_IP}   127.0.0.1

${fixture1}   000D6F00031105FC
${fixture2}   000D6F0002F3B443   # WALC tethered with Lamp, which is used to wake up sensor by winking

${sensor}   000D6F000310E74D
${keypad}   000D6F0010061F00

# How to install driver for relay controller: go to https://www.arduino.cc/en/Guide/ArduinoLeonardoMicro
# from SOFTWARE - DOWNLOADS - Windows ZIP file for non admin install, which contains the "drivers" folder
# follow the instruction to install drivers: https://www.arduino.cc/en/Guide/DriverInstallation
# find port number from Control Panel - Device Manager - Ports - Arduino Leonardo (which may change if you unplug and plug back the cable)
${relay_port}   COM10
# RELAY number can be from 1 to 4, labels could be wrong, try different number in the script, extend the delay to 5 seconds,
# if your script has the correct RELAY number, you should see the keypad is waking up, i.e., the red LED below all the keypad buttons will light up
${relay_number}   RELAY4

${prop_whiteListFromPolaris_fixture_input}   SEPARATOR=\n
...     {
...         "Devices": [
...             {
...                 "Eui64": "${fixture1}"
...             }
...         ]
...     }

${prop_whiteListFromPolaris_sensor_input}   SEPARATOR=\n
...     {
...         "Devices": [
...             {
...                 "Eui64": "${fixture2}"
...             },
...             {
...                 "Eui64": "${sensor}"
...             }
...         ]
...     }

${prop_whiteListFromPolaris_empty_input}   SEPARATOR=\n
...     {
...         "Devices": []
...     }

${prop_URIToDeleteNode_fixture1_input}   ZigBee://${fixture1}.00
${prop_URIToDeleteNode_fixture2_input}   ZigBee://${fixture2}.00
${prop_URIToDeleteNode_sensor_input}   ZigBee://${sensor}.00
${prop_URIToDeleteNode_keypad_input}   ZigBee://${keypad}.00

*** Keywords ***
Setup System
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    Logout

Breakdown System
    [Documentation]   Remove the Master ECU from the site & Delete the site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}
    Run keyword and ignore error   Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.sqlite